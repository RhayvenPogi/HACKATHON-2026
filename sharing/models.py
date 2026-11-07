import uuid

from django.db import models
from django.utils import timezone

from professionals.models import Professional


class ExpiringQuerySet(models.QuerySet):
    def valid(self):
        return self.filter(revoked_at__isnull=True, expires_at__gt=timezone.now())


class SharedAssessment(models.Model):
    """Created only when a citizen explicitly consents to share.
    Contains no name, device ID, or IP address."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    responses = models.JSONField()
    result = models.JSONField()  # Exact process_assessment() output.
    consent_version = models.PositiveSmallIntegerField()
    consent_given_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Shared assessment {self.id}"


class ShareToken(models.Model):
    token_hash = models.CharField(max_length=64, unique=True, editable=False)
    # Deleting a token never deletes the assessment.
    assessment = models.ForeignKey(
        SharedAssessment, on_delete=models.CASCADE, related_name="tokens"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)

    objects = ExpiringQuerySet.as_manager()


class ShareAccessLog(models.Model):
    assessment = models.ForeignKey(
        SharedAssessment, on_delete=models.CASCADE, related_name="access_logs"
    )
    professional = models.ForeignKey(Professional, on_delete=models.PROTECT)
    accessed_at = models.DateTimeField(auto_now_add=True)


class ProfessionalSession(models.Model):
    token_hash = models.CharField(max_length=64, unique=True, editable=False)
    professional = models.ForeignKey(
        Professional, on_delete=models.CASCADE, related_name="sessions"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)

    objects = ExpiringQuerySet.as_manager()