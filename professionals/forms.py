from django import forms
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

from .models import Professional

User = get_user_model()

PROFILE_FIELDS = [
    "full_name",
    "profession",
    "prc_license_number",
    "prc_license_expiry",
    "facility_name",
    "contact_email",
    "contact_number",
]


class ProfessionalCreationForm(forms.ModelForm):
    """Registers a professional AND creates their (non-staff) login."""

    username = forms.CharField(max_length=150)
    password1 = forms.CharField(
        label="Temporary password", widget=forms.PasswordInput
    )
    password2 = forms.CharField(
        label="Confirm temporary password", widget=forms.PasswordInput
    )

    class Meta:
        model = Professional
        fields = PROFILE_FIELDS

    def clean_username(self):
        username = self.cleaned_data["username"].strip()
        if User.objects.filter(username__iexact=username).exists():
            raise ValidationError("This username is already taken.")
        return username

    def clean(self):
        cleaned = super().clean()
        p1, p2 = cleaned.get("password1"), cleaned.get("password2")
        if p1 and p2 and p1 != p2:
            self.add_error("password2", "Passwords do not match.")
        if p1:
            try:
                validate_password(p1)
            except ValidationError as error:
                self.add_error("password1", error)
        return cleaned

    def save(self, commit=True):
        professional = super().save(commit=False)
        professional.user = User.objects.create_user(
            username=self.cleaned_data["username"],
            email=self.cleaned_data["contact_email"],
            password=self.cleaned_data["password1"],
            is_staff=False,
        )
        if commit:
            professional.save()
        return professional