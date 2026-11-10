from django.urls import path

from .views import CheckInView

# Citizens get ONE overall indicator only. Subscale scores are shown only to
# professionals, through sharing. The old /api/assessments/ endpoint is gone.
urlpatterns = [
    path("check-in/", CheckInView.as_view(), name="check-in"),
]