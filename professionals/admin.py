import secrets

from django.contrib import admin, messages

from .forms import PROFILE_FIELDS, ProfessionalCreationForm
from .models import Professional

admin.site.site_header = "FLOW Administration"
admin.site.site_title = "FLOW Admin"
admin.site.index_title = "Mental health professional registry"


@admin.register(Professional)
class ProfessionalAdmin(admin.ModelAdmin):
    add_form = ProfessionalCreationForm
    list_display = (
        "full_name",
        "profession",
        "prc_license_number",
        "prc_license_expiry",
        "facility_name",
        "is_active",
        "must_change_password",
    )
    list_filter = ("profession", "is_active")
    search_fields = ("full_name", "prc_license_number", "facility_name")
    actions = ("deactivate", "activate", "reset_password")

    @admin.display(description="Username")
    def username(self, obj):
        return obj.user.username

    def get_form(self, request, obj=None, **kwargs):
        if obj is None:
            kwargs["form"] = self.add_form
        return super().get_form(request, obj, **kwargs)

    def get_fields(self, request, obj=None):
        if obj is None:
            return ["username", "password1", "password2", *PROFILE_FIELDS]
        return ["username", *PROFILE_FIELDS, "is_active", "created_at", "updated_at"]

    def get_readonly_fields(self, request, obj=None):
        return ("username", "created_at", "updated_at") if obj else ()

    def has_delete_permission(self, request, obj=None):
        return False  # Deactivate instead; keeps an audit trail.

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        if obj.user.is_active != obj.is_active:
            obj.user.is_active = obj.is_active
            obj.user.save(update_fields=["is_active"])

    def _set_active(self, request, queryset, active):
        for professional in queryset.select_related("user"):
            professional.is_active = active
            professional.save(update_fields=["is_active", "updated_at"])
            professional.user.is_active = active
            professional.user.save(update_fields=["is_active"])
        state = "activated" if active else "deactivated"
        self.message_user(
            request, f"{queryset.count()} professional(s) {state}.", messages.SUCCESS
        )

    @admin.action(description="Deactivate selected professionals")
    def deactivate(self, request, queryset):
        self._set_active(request, queryset, False)

    @admin.action(description="Activate selected professionals")
    def activate(self, request, queryset):
        self._set_active(request, queryset, True)

    @admin.action(description="Reset password (shows a one-time temporary password)")
    def reset_password(self, request, queryset):
        from sharing.models import ProfessionalSession  # avoid circular import

        for professional in queryset.select_related("user"):
            temporary = secrets.token_urlsafe(9)
            professional.user.set_password(temporary)
            professional.user.save(update_fields=["password"])
            professional.must_change_password = True
            professional.save(update_fields=["must_change_password", "updated_at"])
            ProfessionalSession.objects.valid().filter(
                professional=professional
            ).update(revoked_at=timezone.now())
            self.message_user(
                request,
                f"{professional.full_name}: temporary password {temporary} "
                "(shown once; they must change it at next sign-in).",
                messages.WARNING,
            )