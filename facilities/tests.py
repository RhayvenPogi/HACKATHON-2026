import json

from django.contrib.auth.models import Group, User
from django.core.cache import cache
from django.core.management import call_command
from django.test import TestCase

from professionals.roles import ADMIN_GROUP

from .models import Facility

PORTAL = "/portal/api/facilities/"
PUBLIC = "/api/facilities/"


def valid(**overrides):
    data = {
        "name": "Sample Facility (test)",
        "facility_type": "hospital",
        "address": "Sample address, San Fernando City",
        "latitude": "16.616000",
        "longitude": "120.316000",
        "contact_number": "",
        "hours": "",
        "source_note": "",
        "is_verified": False,
        "is_active": True,
    }
    data.update(overrides)
    return data


class FacilityPortalTests(TestCase):
    def setUp(self):
        cache.clear()
        call_command("setup_admin_roles", verbosity=0)
        admin = User.objects.create_user("flowadmin", password="Admin-Pass-2026!", is_staff=True)
        admin.groups.add(Group.objects.get(name=ADMIN_GROUP))
        self.client.force_login(admin)

    def post(self, url, data):
        return self.client.post(url, json.dumps(data), content_type="application/json")

    def test_requires_admin(self):
        self.client.logout()
        self.assertEqual(self.client.get(PORTAL).status_code, 401)

    def test_create_and_list(self):
        response = self.post(PORTAL, valid())
        self.assertEqual(response.status_code, 201, response.content)
        listing = self.client.get(PORTAL).json()
        self.assertEqual(len(listing["facilities"]), 1)
        self.assertTrue(listing["types"])

    def test_rejects_coordinates_outside_philippines(self):
        # Latitude and longitude swapped by mistake.
        response = self.post(PORTAL, valid(latitude="120.316000", longitude="16.616000"))
        self.assertEqual(response.status_code, 400)
        self.assertIn("latitude", response.json()["fields"])

    def test_verified_requires_source(self):
        response = self.post(PORTAL, valid(is_verified=True, source_note=""))
        self.assertEqual(response.status_code, 400)
        self.assertIn("source_note", response.json()["fields"])

    def test_update_and_delete(self):
        pk = self.post(PORTAL, valid()).json()["facility"]["id"]
        updated = self.post(f"{PORTAL}{pk}/", valid(name="Renamed (test)"))
        self.assertEqual(updated.json()["facility"]["name"], "Renamed (test)")
        self.assertEqual(self.post(f"{PORTAL}{pk}/delete/", {}).status_code, 200)
        self.assertEqual(Facility.objects.count(), 0)


class PublicFacilityTests(TestCase):
    def make(self, **kw):
        defaults = dict(
            name="F", facility_type="clinic", address="A",
            latitude="16.6", longitude="120.3",
        )
        defaults.update(kw)
        return Facility.objects.create(**defaults)

    def test_only_verified_active_are_public(self):
        self.make(name="Unverified")
        self.make(name="Verified", is_verified=True, source_note="City Health Office list")
        self.make(name="Hidden", is_verified=True, source_note="x", is_active=False)
        data = self.client.get(PUBLIC).json()["facilities"]
        self.assertEqual([f["name"] for f in data], ["Verified"])
        self.assertEqual(data[0]["source_note"], "City Health Office list")
        self.assertIsInstance(data[0]["latitude"], float)

    def test_public_endpoint_is_read_only(self):
        self.assertEqual(self.client.post(PUBLIC, {}).status_code, 405)
