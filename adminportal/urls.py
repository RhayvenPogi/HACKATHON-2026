from django.urls import path

from . import facility_views, views

app_name = "portal"

urlpatterns = [
    path("", views.index, name="index"),
    path("api/login/", views.api_login, name="login"),
    path("api/logout/", views.api_logout, name="logout"),
    path("api/me/", views.api_me, name="me"),
    path("api/dashboard/", views.api_dashboard, name="dashboard"),
    path("api/professionals/", views.api_professionals, name="professionals"),
    path("api/professionals/<uuid:pk>/action/", views.api_professional_action, name="professional-action"),
    path("api/settings/", views.api_settings, name="settings"),
    path("api/facilities/", facility_views.api_facilities, name="facilities"),
    path("api/facilities/<uuid:pk>/", facility_views.api_facility_update, name="facility-update"),
    path("api/facilities/<uuid:pk>/delete/", facility_views.api_facility_delete, name="facility-delete"),
]
