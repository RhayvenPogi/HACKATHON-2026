from django.urls import path

from .views import (
    ProfessionalLoginView,
    ProfessionalLogoutView,
    ProfessionalOpenShareView,
    ProfessionalPasswordChangeView,
    ShareCreateView,
    ShareRevokeView,
)

# Tokens are NEVER placed in URL paths (paths appear in server logs).
urlpatterns = [
    path("shares/", ShareCreateView.as_view(), name="share-create"),
    path("shares/revoke/", ShareRevokeView.as_view(), name="share-revoke"),
    path("professional/login/", ProfessionalLoginView.as_view(), name="professional-login"),
    path("professional/logout/", ProfessionalLogoutView.as_view(), name="professional-logout"),
    path("professional/shares/open/", ProfessionalOpenShareView.as_view(), name="professional-open-share"),
    path("professional/password/", ProfessionalPasswordChangeView.as_view(), name="professional-password"),
]