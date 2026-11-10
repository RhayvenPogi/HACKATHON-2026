import json
from datetime import timedelta

from django.contrib.auth.models import Group, User
from django.core.cache import cache
from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone

from professionals.models import Professional
from professionals.roles import ADMIN_GROUP

API = "/portal/api/"
ADMIN_PASSWORD = "Admin-Pass-2026!"


class PortalTestBase(TestCase):
    def setUp(self):
        cache.clear()
        call_command("setup_admin_roles", verbosity=0)
        self.admin = User.objects.create_user("flowadmin", password=ADMIN_PASSWORD, is_staff=True)
        self.admin.groups.add(Group.objects.get(name=ADMIN_GROUP))

    def post(self, path, data=None):
        return self.client.post(API + path, json.dumps(data or {}), content_type="application/json")

    def sign_in(self):
        self.client.force_login(self.admin)

    def register(self, **overrides):
        payload = {
            "full_name": "Sample Professional (test)",
            "username": "testpro",
            "profession": "psychologist",
            "prc_license_number": "0123456",
            "prc_license_expiry": (timezone.localdate() + timedelta(days=365)).isoformat(),
            "facility_name": "Sample Facility (test)",
            "contact_email": "pro@example.com",
            "contact_number": "",
        }
        payload.update(overrides)
        return self.post("professionals/", payload)

    def approve(self, pk):
        return self.post(f"professionals/{pk}/action/", {"action": "approve", "checklist": True})


class AuthTests(PortalTestBase):
    def test_index_renders(self):
        response = self.client.get("/portal/")
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "MUNI Administrator Portal")

    def test_api_requires_login(self):
        self.assertEqual(self.client.get(API + "me/").status_code, 401)
        self.assertEqual(self.client.get(API + "professionals/").status_code, 401)

    def test_admin_can_sign_in(self):
        response = self.post("login/", {"username": "flowadmin", "password": ADMIN_PASSWORD})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.client.get(API + "me/").status_code, 200)

    def test_non_admin_account_cannot_sign_in(self):
        User.objects.create_user("someone", password=ADMIN_PASSWORD)
        response = self.post("login/", {"username": "someone", "password": ADMIN_PASSWORD})
        self.assertEqual(response.status_code, 401)


class WorkflowTests(PortalTestBase):
    def setUp(self):
        super().setUp()
        self.sign_in()

    def test_register_creates_pending_locked_account(self):
        response = self.register()
        self.assertEqual(response.status_code, 201, response.content)
        self.assertEqual(response.json()["professional"]["status"], "pending")
        p = Professional.objects.get(prc_license_number="0123456")
        self.assertFalse(p.user.is_active)
        self.assertFalse(p.user.has_usable_password())
        self.assertFalse(p.can_receive_shared_assessments)

    def test_invalid_registration_returns_field_errors(self):
        response = self.register(prc_license_number="AB12")
        self.assertEqual(response.status_code, 400)
        self.assertIn("prc_license_number", response.json()["fields"])

    def test_approve_requires_checklist(self):
        pk = self.register().json()["professional"]["id"]
        response = self.post(f"professionals/{pk}/action/", {"action": "approve"})
        self.assertEqual(response.status_code, 400)

    def test_approve_issues_temp_password_that_works_in_app(self):
        pk = self.register().json()["professional"]["id"]
        response = self.approve(pk)
        self.assertEqual(response.status_code, 200, response.content)
        temporary = response.json()["temporary_password"]

        app_login = self.client.post(
            "/api/professional/login/",
            json.dumps({"username": "testpro", "password": temporary}),
            content_type="application/json",
        )
        self.assertEqual(app_login.status_code, 200, app_login.content)
        self.assertTrue(app_login.json()["must_change_password"])

    def test_deactivate_and_invalid_transition(self):
        pk = self.register().json()["professional"]["id"]
        self.approve(pk)
        first = self.post(f"professionals/{pk}/action/", {"action": "deactivate"})
        second = self.post(f"professionals/{pk}/action/", {"action": "deactivate"})
        self.assertEqual(first.json()["professional"]["status"], "deactivated")
        self.assertEqual(second.status_code, 409)

    def test_dashboard_contains_no_assessment_data(self):
        response = self.client.get(API + "dashboard/?range=7")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(set(response.json()), {"activity", "professions", "expiring_soon"})
        self.assertNotIn(b"assessment", response.content.lower())

    def test_settings_password_change(self):
        wrong = self.post("settings/", {
            "display_name": "Admin", "current_password": "nope",
            "new_password": "Bagong-Admin-2026!", "confirm_password": "Bagong-Admin-2026!",
        })
        self.assertEqual(wrong.status_code, 400)
        ok = self.post("settings/", {
            "display_name": "Admin", "current_password": ADMIN_PASSWORD,
            "new_password": "Bagong-Admin-2026!", "confirm_password": "Bagong-Admin-2026!",
        })
        self.assertEqual(ok.status_code, 200)
        self.admin.refresh_from_db()
        self.assertTrue(self.admin.check_password("Bagong-Admin-2026!"))
