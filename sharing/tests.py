from datetime import timedelta
from io import StringIO

from django.contrib import admin
from django.contrib.auth.models import User
from django.core.cache import cache
from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from professionals.models import Professional

from .models import ProfessionalSession, ShareAccessLog, SharedAssessment, ShareToken
from .tokens import hash_token

RESPONSES = [1] * 42
PASSWORD = "Kalmado-2026!x"


def make_professional(username="drcruz", license_days=365, must_change_password=False):
    user = User.objects.create_user(username, password=PASSWORD)
    return Professional.objects.create(
        user=user,
        full_name="Dr. Sample Cruz (test)",
        profession=Professional.Profession.PSYCHOLOGIST,
        prc_license_number=str(1000000 + user.pk),
        prc_license_expiry=timezone.localdate() + timedelta(days=license_days),
        facility_name="Sample Facility (test)",
        contact_email="cruz@example.com",
        must_change_password=must_change_password,
    )


class BaseSharingTest(TestCase):
    def setUp(self):
        cache.clear()  # Reset rate-limit counters between tests.
        self.client = APIClient()

    def create_share(self, **overrides):
        payload = {"responses": RESPONSES, "consent_version": 1, "consent_given": True}
        payload.update(overrides)
        return self.client.post("/api/shares/", payload, format="json")

    def login(self, username="drcruz", password=PASSWORD):
        return self.client.post(
            "/api/professional/login/",
            {"username": username, "password": password},
            format="json",
        )


class ShareCreateTests(BaseSharingTest):
    def test_creates_share_and_stores_only_hash(self):
        response = self.create_share()
        self.assertEqual(response.status_code, 201, response.content)
        data = response.json()
        raw = data["token"]

        self.assertEqual(data["share_url"], f"muni://share/{raw}")
        self.assertFalse(ShareToken.objects.filter(token_hash=raw).exists())
        token = ShareToken.objects.get(token_hash=hash_token(raw))
        self.assertEqual(token.assessment.responses, RESPONSES)
        self.assertAlmostEqual(
            (token.expires_at - token.created_at).total_seconds(),
            timedelta(days=15).total_seconds(),
            delta=5,
        )

    def test_scores_on_server(self):
        raw = self.create_share().json()["token"]
        result = ShareToken.objects.get(token_hash=hash_token(raw)).assessment.result
        self.assertEqual(result["assessment"]["depression"]["score"], 14)

    def test_requires_explicit_consent(self):
        response = self.create_share(consent_given=False)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(SharedAssessment.objects.count(), 0)

    def test_rejects_invalid_responses(self):
        response = self.create_share(responses=[1] * 41)
        self.assertEqual(response.status_code, 400)


class ShareRevokeTests(BaseSharingTest):
    def test_revoke_then_not_found(self):
        raw = self.create_share().json()["token"]
        first = self.client.post("/api/shares/revoke/", {"token": raw}, format="json")
        second = self.client.post("/api/shares/revoke/", {"token": raw}, format="json")
        self.assertEqual(first.status_code, 204)
        self.assertEqual(second.status_code, 404)


class ProfessionalLoginTests(BaseSharingTest):
    def test_login_returns_session_stored_as_hash(self):
        make_professional()
        response = self.login()
        self.assertEqual(response.status_code, 200)
        raw = response.json()["token"]
        self.assertTrue(
            ProfessionalSession.objects.filter(token_hash=hash_token(raw)).exists()
        )

    def test_wrong_password_rejected(self):
        make_professional()
        self.assertEqual(self.login(password="wrong").status_code, 401)

    def test_expired_license_rejected(self):
        make_professional(license_days=-1)
        self.assertEqual(self.login().status_code, 401)

    def test_non_professional_user_rejected(self):
        User.objects.create_user("citizen", password=PASSWORD)
        self.assertEqual(self.login(username="citizen").status_code, 401)


class ProfessionalOpenShareTests(BaseSharingTest):
    def setUp(self):
        super().setUp()
        self.professional = make_professional()
        self.session_token = self.login().json()["token"]
        self.share_token = self.create_share().json()["token"]

    def open_share(self, authorized=True):
        client = APIClient()
        if authorized:
            client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.session_token}")
        return client.post(
            "/api/professional/shares/open/", {"token": self.share_token}, format="json"
        )

    def test_opens_share_and_logs_access(self):
        response = self.open_share()
        self.assertEqual(response.status_code, 200, response.content)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["assessment"]["depression"]["score"], 14)
        self.assertEqual(len(data["responses"]), 42)
        self.assertEqual(response["Cache-Control"], "no-store")
        self.assertEqual(ShareAccessLog.objects.count(), 1)

    def test_requires_authentication(self):
        self.assertEqual(self.open_share(authorized=False).status_code, 401)

    def test_expired_share_not_found(self):
        ShareToken.objects.update(expires_at=timezone.now() - timedelta(seconds=1))
        self.assertEqual(self.open_share().status_code, 404)

    def test_revoked_share_not_found(self):
        self.client.post("/api/shares/revoke/", {"token": self.share_token}, format="json")
        self.assertEqual(self.open_share().status_code, 404)

    def test_logout_ends_session(self):
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {self.session_token}")
        self.assertEqual(client.post("/api/professional/logout/").status_code, 204)
        self.assertEqual(self.open_share().status_code, 401)

    def test_deactivated_professional_loses_access(self):
        self.professional.is_active = False
        self.professional.save()
        self.assertEqual(self.open_share().status_code, 401)


class MaintenanceTests(BaseSharingTest):
    def test_purge_deletes_tokens_but_keeps_assessments(self):
        self.create_share()
        ShareToken.objects.update(expires_at=timezone.now() - timedelta(seconds=1))
        call_command("purge_expired_shares", stdout=StringIO())
        self.assertEqual(ShareToken.objects.count(), 0)
        self.assertEqual(SharedAssessment.objects.count(), 1)

    def test_no_sharing_models_in_admin(self):
        app_labels = {model._meta.app_label for model in admin.site._registry}
        self.assertNotIn("sharing", app_labels)

class PasswordChangeTests(BaseSharingTest):
    NEW_PASSWORD = "Bagong-Lihim-2026!"

    def setUp(self):
        super().setUp()
        make_professional(must_change_password=True)
        self.session_token = self.login().json()["token"]
        self.share_token = self.create_share().json()["token"]
        self.pro = APIClient()
        self.pro.credentials(HTTP_AUTHORIZATION=f"Bearer {self.session_token}")

    def change(self, current=PASSWORD, new=NEW_PASSWORD):
        return self.pro.post(
            "/api/professional/password/",
            {"current_password": current, "new_password": new},
            format="json",
        )

    def open_share(self):
        return self.pro.post(
            "/api/professional/shares/open/", {"token": self.share_token}, format="json"
        )

    def test_login_reports_change_required(self):
        self.assertTrue(self.login().json()["must_change_password"])

    def test_open_blocked_until_password_changed(self):
        self.assertEqual(self.open_share().status_code, 403)

    def test_change_password_unblocks_access(self):
        self.assertEqual(self.change().status_code, 204)
        self.assertEqual(self.open_share().status_code, 200)

    def test_wrong_current_password_rejected(self):
        self.assertEqual(self.change(current="wrong").status_code, 400)