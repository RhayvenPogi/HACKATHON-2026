from django.contrib.auth.models import Group, Permission
from django.core.management.base import BaseCommand, CommandError

from professionals.roles import ADMIN_GROUP, ADMIN_PERMISSIONS


class Command(BaseCommand):
    help = "Create or refresh the FLOW Administrators group (professionals only)."

    def handle(self, *args, **options):
        perms = Permission.objects.filter(
            content_type__app_label="professionals",
            codename__in=ADMIN_PERMISSIONS,
        )
        if perms.count() != len(ADMIN_PERMISSIONS):
            raise CommandError("Professional permissions missing. Run migrate first.")

        group, created = Group.objects.get_or_create(name=ADMIN_GROUP)
        group.permissions.set(perms)
        verb = "Created" if created else "Updated"
        if options["verbosity"] > 0:
            self.stdout.write(self.style.SUCCESS(f"{verb} group '{ADMIN_GROUP}'."))