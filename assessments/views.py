
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from .serializers import AssessmentRequestSerializer
from src.dass42.assessment import process_assessment


class AssessmentAPIView(APIView):
    # Local development only. Add real authentication
    # and authorization before handling citizen data.
    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = AssessmentRequestSerializer(
            data=request.data
        )

        if not serializer.is_valid():
            return Response(
                {
                    "status": "error",
                    "errors": serializer.errors
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            result = process_assessment(
                serializer.validated_data["responses"]
            )

            return Response(
                result,
                status=status.HTTP_200_OK
            )

        except (ValueError, TypeError) as error:
            return Response(
                {
                    "status": "error",
                    "message": str(error)
                },
                status=status.HTTP_400_BAD_REQUEST
            )
