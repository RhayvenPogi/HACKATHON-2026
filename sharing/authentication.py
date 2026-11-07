from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework.exceptions import AuthenticationFailed

from .models import ProfessionalSession
from .tokens import hash_token


class ProfessionalTokenAuthentication(BaseAuthentication):
    """Authorization: Bearer <session token>. Re-checks professional status
    on every request, so deactivation or license expiry takes effect at once."""

    def authenticate(self, request):
        parts = get_authorization_header(request).split()
        if not parts or parts[0].lower() != b"bearer":
            return None
        if len(parts) != 2:
            raise AuthenticationFailed("Invalid authorization header.")
        try:
            raw = parts[1].decode("ascii")
        except UnicodeError:
            raise AuthenticationFailed("Invalid authorization header.")

        session = (
            ProfessionalSession.objects.valid()
            .select_related("professional__user")
            .filter(token_hash=hash_token(raw))
            .first()
        )
        if session is None or not session.professional.can_receive_shared_assessments:
            raise AuthenticationFailed("Session expired or not authorized.")
        return (session.professional.user, session)

    def authenticate_header(self, request):
        return "Bearer"