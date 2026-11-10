from django.urls import path

from .views import facility_list

urlpatterns = [
    path("facilities/", facility_list, name="facility-list"),
]
