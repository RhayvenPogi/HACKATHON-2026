from django.contrib.auth import authenticate
from django.db import transaction
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from src.dass42.assessment import process_assessment

from .authentication import ProfessionalTokenAuthentication
from .conf import session_ttl, share_ttl, share_url_prefix
from .models import ProfessionalSession, ShareAccessLog, SharedAssessment, ShareToken
from .serializers import (
    ProfessionalLoginSerializer,
    ShareCreateSerializer,
    TokenSerializer,
    PasswordChangeSerializer,
)
from .tokens import generate_token, hash_token

NO_STORE = {"Cache-Control": "no-store"}


def _error(errors, code=status.HTTP_400_BAD_REQUEST):
    return Response({"status": "error", "errors": errors}, status=code, headers=NO_STORE)


def _not_found():
    return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND, headers=NO_STORE)


class ShareCreateView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "share_create"

    def post(self, request):
        serializer = ShareCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return _error(serializer.errors)

        responses = serializer.validated_data["responses"]
        try:
            result = process_assessment(responses)  # Server-side re-score.
        except (ValueError, TypeError):
            return _error({"responses": ["Could not process assessment."]})

        raw = generate_token()
        now = timezone.now()
        with transaction.atomic():
            assessment = SharedAssessment.objects.create(
                responses=responses,
                result=result,
                consent_version=serializer.validated_data["consent_version"],
                consent_given_at=now,
            )
            token = ShareToken.objects.create(
                assessment=assessment,
                token_hash=hash_token(raw),
                expires_at=now + share_ttl(),
            )

        return Response(
            {
                "token": raw,
                "share_url": f"{share_url_prefix()}{raw}",
                "expires_at": token.expires_at.isoformat(),
            },
            status=status.HTTP_201_CREATED,
            headers=NO_STORE,
        )


class ShareRevokeView(APIView):
    """Holding the token is what authorizes revoking it (citizens have no accounts)."""

    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "share_revoke"

    def post(self, request):
        serializer = TokenSerializer(data=request.data)
        if not serializer.is_valid():
            return _error(serializer.errors)

        token = (
            ShareToken.objects.valid()
            .filter(token_hash=hash_token(serializer.validated_data["token"]))
            .first()
        )
        if token is None:
            return _not_found()
        token.revoked_at = timezone.now()
        token.save(update_fields=["revoked_at"])
        return Response(status=status.HTTP_204_NO_CONTENT, headers=NO_STORE)


class ProfessionalLoginView(APIView):
    authentication_classes = []
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "professional_login"

    def post(self, request):
        serializer = ProfessionalLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return _error(serializer.errors)

        user = authenticate(
            request,
            username=serializer.validated_data["username"],
            password=serializer.validated_data["password"],
        )
        professional = getattr(user, "professional", None) if user else None
        if professional is None or not professional.can_receive_shared_assessments:
            # Same message for every failure: reveals nothing about which check failed.
            return Response(
                {"detail": "Invalid credentials or account not authorized."},
                status=status.HTTP_401_UNAUTHORIZED,
                headers=NO_STORE,
            )

        raw = generate_token()
        session = ProfessionalSession.objects.create(
            professional=professional,
            token_hash=hash_token(raw),
            expires_at=timezone.now() + session_ttl(),
        )
        return Response(
            {
                "token": raw,
                "expires_at": session.expires_at.isoformat(),
                "must_change_password": professional.must_change_password,
                "professional": {
                    "full_name": professional.full_name,
                    "profession": professional.get_profession_display(),
                },
            },
            headers=NO_STORE,
        )


class ProfessionalLogoutView(APIView):
    authentication_classes = [ProfessionalTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        session = request.auth
        session.revoked_at = timezone.now()
        session.save(update_fields=["revoked_at"])
        return Response(status=status.HTTP_204_NO_CONTENT, headers=NO_STORE)


class ProfessionalOpenShareView(APIView):
    authentication_classes = [ProfessionalTokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = TokenSerializer(data=request.data)

        if request.user.professional.must_change_password:
            return Response(
                {"detail": "Password change required."},
                status=status.HTTP_403_FORBIDDEN,
                headers=NO_STORE,
            )

        if not serializer.is_valid():
            return _error(serializer.errors)

        token = (
            ShareToken.objects.valid()
            .select_related("assessment")
            .filter(token_hash=hash_token(serializer.validated_data["token"]))
            .first()
        )
        if token is None:
            return _not_found()

        assessment = token.assessment
        ShareAccessLog.objects.create(
            assessment=assessment, professional=request.user.professional
        )
        return Response(
            {
                **assessment.result,
                "responses": assessment.responses,
                "shared_at": assessment.created_at.isoformat(),
                "expires_at": token.expires_at.isoformat(),
            },
            headers=NO_STORE,
        )

class ProfessionalPasswordChangeView(APIView):
    authentication_classes = [ProfessionalTokenAuthentication]
    permission_classes = [IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "professional_login"

    def post(self, request):
        serializer = PasswordChangeSerializer(data=request.data)
        if not serializer.is_valid():
            return _error(serializer.errors)

        user = request.user
        current = serializer.validated_data["current_password"]
        new = serializer.validated_data["new_password"]

        if not user.check_password(current):
            return _error({"current_password": ["Current password is incorrect."]})
        if new == current:
            return _error({"new_password": ["New password must be different."]})
        try:
            validate_password(new, user)
        except DjangoValidationError as error:
            return _error({"new_password": list(error.messages)})

        user.set_password(new)
        user.save(update_fields=["password"])
        professional = user.professional
        professional.must_change_password = False
        professional.save(update_fields=["must_change_password", "updated_at"])

        # Sign out every other session for this professional.
        ProfessionalSession.objects.valid().filter(professional=professional).exclude(
            pk=request.auth.pk
        ).update(revoked_at=timezone.now())
        return Response(status=status.HTTP_204_NO_CONTENT, headers=NO_STORE)