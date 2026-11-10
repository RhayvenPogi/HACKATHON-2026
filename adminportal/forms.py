from django import forms
from django.contrib.auth import get_user_model
from django.contrib.auth.validators import UnicodeUsernameValidator
from django.core.exceptions import ValidationError
from django.utils import timezone

from professionals.models import Professional

User = get_user_model()


class PortalRegistrationForm(forms.ModelForm):
    """Registers a professional as PENDING with a locked account.
    The account is unlocked (with a temporary password) only on approval."""

    username = forms.CharField(max_length=150, validators=[UnicodeUsernameValidator()])

    class Meta:
        model = Professional
        fields = [
            "full_name",
            "profession",
            "prc_license_number",
            "prc_license_expiry",
            "facility_name",
            "contact_email",
            "contact_number",
        ]

    def clean_username(self):
        username = self.cleaned_data["username"].strip()
        if User.objects.filter(username__iexact=username).exists():
            raise ValidationError("This username is already taken.")
        return username

    def clean_prc_license_expiry(self):
        value = self.cleaned_data["prc_license_expiry"]
        if value < timezone.localdate():
            raise ValidationError("This license has already expired.")
        return value

    def save(self, commit=True):
        professional = super().save(commit=False)
        user = User(
            username=self.cleaned_data["username"],
            email=self.cleaned_data["contact_email"],
            is_active=False,
            is_staff=False,
        )
        user.set_unusable_password()
        user.save()
        professional.user = user
        professional.verification_status = Professional.Verification.PENDING
        professional.is_active = False
        professional.must_change_password = True
        professional.save()
        return professional
