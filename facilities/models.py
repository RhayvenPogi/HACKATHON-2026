import uuid

from django.core.exceptions import ValidationError
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils import timezone

# Rough bounding box of the Philippines. Catches swapped or mistyped
# coordinates (e.g. 120.3, 16.6 entered the wrong way round).
PH_LAT = (4.5, 21.5)
PH_LNG = (116.0, 127.0)


class FacilityQuerySet(models.QuerySet):
    def public(self):
        return self.filter(is_verified=True, is_active=True)


class Facility(models.Model):
    class Type(models.TextChoices):
        HOSPITAL = "hospital", "Hospital"
        RHU = "rhu", "Rural Health Unit / Health Center"
        CLINIC = "clinic", "Mental health clinic"
        COUNSELING = "counseling", "Counseling center"
        OTHER = "other", "Other"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    facility_type = models.CharField(max_length=20, choices=Type.choices)
    address = models.CharField(max_length=300)
    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        validators=[MinValueValidator(PH_LAT[0]), MaxValueValidator(PH_LAT[1])],
    )
    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        validators=[MinValueValidator(PH_LNG[0]), MaxValueValidator(PH_LNG[1])],
    )
    contact_number = models.CharField(max_length=40, blank=True)
    hours = models.CharField(max_length=120, blank=True)
    source_note = models.CharField(
        max_length=300,
        blank=True,
        help_text="Where this listing came from and when it was checked.",
    )
    is_verified = models.BooleanField(default=False)
    verified_at = models.DateTimeField(null=True, blank=True, editable=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = FacilityQuerySet.as_manager()

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "facilities"

    def __str__(self):
        return self.name

    def clean(self):
        if self.is_verified and not self.source_note.strip():
            raise ValidationError(
                {"source_note": "A verified facility needs a source (who confirmed it and when)."}
            )

    def save(self, *args, **kwargs):
        if self.is_verified and self.verified_at is None:
            self.verified_at = timezone.now()
        if not self.is_verified:
            self.verified_at = None
        super().save(*args, **kwargs)
