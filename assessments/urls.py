
from django.urls import path
from .views import AssessmentAPIView

urlpatterns = [
    path(
        "assessments/",
        AssessmentAPIView.as_view(),
        name="assessment"
    ),
]
