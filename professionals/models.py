import uuid

from django.conf import settings
from django.core.validators import RegexValidator
from django.db import models
from django.utils import timezone

prc_license_validator = RegexValidator(
    regex=r"^\d{4,10}$",
    message="PRC license number must contain digits only.",
)


class Professional(models.Model):
    class Profession(models.TextChoices):
        PSYCHIATRIST = "psychiatrist", "Psychiatrist"
        PSYCHOLOGIST = "psychologist", "Psychologist"
        PSYCHIATRIC_NURSE = "psychiatric_nurse", "Psychiatric Nurse"
        GUIDANCE_COUNSELOR = "guidance_counselor", "Guidance Counselor"
        OTHER = "other", "Other"

    class Verification(models.TextChoices):
        PENDING = "pending", "Pending verification"
        VERIFIED = "verified", "Verified"
        REJECTED = "rejected", "Rejected"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="professional",
    )
    full_name = models.CharField(max_length=150)
    profession = models.CharField(max_length=32, choices=Profession.choices)
    prc_license_number = models.CharField(
        "PRC license number",
        max_length=10,
        unique=True,
        validators=[prc_license_validator],
    )
    prc_license_expiry = models.DateField("PRC license expiry")
    facility_name = models.CharField(max_length=200)
    contact_email = models.EmailField()
    contact_number = models.CharField(max_length=20, blank=True)
    is_active = models.BooleanField(default=True)
    must_change_password = models.BooleanField(default=True)
    verification_status = models.CharField(
        max_length=10,
        choices=Verification.choices,
        default=Verification.VERIFIED,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["full_name"]

    def __str__(self):
        return f"{self.full_name} ({self.get_profession_display()})"

    @property
    def license_is_current(self):
        return self.prc_license_expiry >= timezone.localdate()

    @property
    def can_receive_shared_assessments(self):
        return (
            self.verification_status == self.Verification.VERIFIED
            and self.is_active
            and self.user.is_active
            and self.license_is_current
        )