from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from src.dass21.indicator import overall_indicator

from .serializers import AssessmentRequestSerializer

NOTICE = (
    "This is a general screening indicator, not a diagnosis. Only a "
    "qualified professional can assess your mental health."
)


class CheckInView(APIView):
    """Returns ONE overall indicator. Answers are not stored, and no
    subscale scores or labels are returned."""

    authentication_classes = []
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = AssessmentRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"status": "error", "errors": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )
        level = overall_indicator(serializer.validated_data["responses"])
        return Response(
            {"status": "success", "indicator": level, "notice": NOTICE},
            headers={"Cache-Control": "no-store"},
        )