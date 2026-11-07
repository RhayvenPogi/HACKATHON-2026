from django.core.management.base import BaseCommand
from django.db.models import Q
from django.utils import timezone

from sharing.models import ProfessionalSession, ShareToken


class Command(BaseCommand):
    help = (
        "Delete expired or revoked share tokens and professional sessions. "
        "Never deletes shared assessments."
    )

    def handle(self, *args, **options):
        stale = Q(expires_at__lte=timezone.now()) | Q(revoked_at__isnull=False)
        tokens, _ = ShareToken.objects.filter(stale).delete()
        sessions, _ = ProfessionalSession.objects.filter(stale).delete()
        self.stdout.write(
            self.style.SUCCESS(
                f"Deleted {tokens} share token(s) and {sessions} professional session(s)."
            )
        )