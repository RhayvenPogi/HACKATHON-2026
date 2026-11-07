from datetime import timedelta

from django.contrib import admin
from django.contrib.auth.models import Group, User
from django.core.exceptions import ValidationError
from django.core.management import call_command
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

from .models import Professional
from .roles import ADMIN_GROUP, ADMIN_PERMISSIONS


class AdminScopeTests(TestCase):
    def test_no_assessment_models_in_admin(self):
        """Admins must never see citizen assessment data."""
        app_labels = {model._meta.app_label for model in admin.site._registry}
        self.assertNotIn("assessments", app_labels)


class RoleSetupTests(TestCase):
    def test_group_has_only_professional_permissions_and_is_idempotent(self):
        call_command("setup_admin_roles", verbosity=0)
        call_command("setup_admin_roles", verbosity=0)
        group = Group.objects.get(name=ADMIN_GROUP)
        codenames = set(group.permissions.values_list("codename", flat=True))
        self.assertEqual(codenames, set(ADMIN_PERMISSIONS))


class ValidationTests(TestCase):
    def test_license_number_rejects_letters(self):
        user = User.objects.create_user("p1", password="unused-Pass-123")
        professional = Professional(
            user=user,
            full_name="Test Person",
            profession=Professional.Profession.PSYCHOLOGIST,
            prc_license_number="AB12345",
            prc_license_expiry=timezone.localdate() + timedelta(days=365),
            facility_name="Test Facility",
            contact_email="test@example.com",
        )
        with self.assertRaises(ValidationError):
            professional.full_clean()


class AdminAccessTests(TestCase):
    def setUp(self):
        call_command("setup_admin_roles", verbosity=0)
        self.staff = User.objects.create_user(
            "flowadmin", password="Admin-Pass-2026!", is_staff=True
        )
        self.staff.groups.add(Group.objects.get(name=ADMIN_GROUP))
        self.client.force_login(self.staff)

    def test_can_open_professional_list(self):
        url = reverse("admin:professionals_professional_changelist")
        self.assertEqual(self.client.get(url).status_code, 200)

    def test_cannot_open_user_admin(self):
        url = reverse("admin:auth_user_changelist")
        self.assertEqual(self.client.get(url).status_code, 403)

    def test_registers_professional_with_non_staff_login(self):
        url = reverse("admin:professionals_professional_add")
        response = self.client.post(url, {
            "username": "drsantos",
            "password1": "Kalmado-2026!x",
            "password2": "Kalmado-2026!x",
            "full_name": "Dr. Maria Santos",
            "profession": Professional.Profession.PSYCHIATRIST,
            "prc_license_number": "0123456",
            "prc_license_expiry": (timezone.localdate() + timedelta(days=365)).isoformat(),
            "facility_name": "Sample Facility (test data)",
            "contact_email": "santos@example.com",
            "contact_number": "",
        })
        self.assertEqual(response.status_code, 302)
        professional = Professional.objects.get(prc_license_number="0123456")
        self.assertTrue(professional.user.check_password("Kalmado-2026!x"))
        self.assertFalse(professional.user.is_staff)
        self.assertTrue(professional.can_receive_shared_assessments)

    def test_cannot_delete_professionals(self):
        url = reverse("admin:professionals_professional_changelist")
        response = self.client.get(url)
        self.assertNotContains(response, "Delete selected")