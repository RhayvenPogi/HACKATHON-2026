
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("assessments.urls")),
    path("api/", include("sharing.urls")),
    path("portal/", include("adminportal.urls")),
]
