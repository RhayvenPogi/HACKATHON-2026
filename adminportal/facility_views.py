"""Portal API for managing facilities (admins only)."""

from django import forms
from django.utils import timezone
from django.views.decorators.http import require_POST

from facilities.models import Facility

from .views import _body, _json, admin_api


class FacilityForm(forms.ModelForm):
    class Meta:
        model = Facility
        fields = [
            "name",
            "facility_type",
            "address",
            "latitude",
            "longitude",
            "contact_number",
            "hours",
            "source_note",
            "is_verified",
            "is_active",
        ]


def serialize_facility(f):
    return {
        "id": str(f.id),
        "name": f.name,
        "facility_type": f.facility_type,
        "type": f.get_facility_type_display(),
        "address": f.address,
        "latitude": float(f.latitude),
        "longitude": float(f.longitude),
        "contact_number": f.contact_number,
        "hours": f.hours,
        "source_note": f.source_note,
        "is_verified": f.is_verified,
        "is_active": f.is_active,
        "verified_at": timezone.localtime(f.verified_at).date().isoformat() if f.verified_at else None,
        "updated": timezone.localtime(f.updated_at).date().isoformat(),
    }


def _form_errors(form):
    return _json(
        {
            "error": "Please correct the fields below.",
            "fields": {k: [str(m) for m in v] for k, v in form.errors.items()},
        },
        400,
    )


def _form_data(data):
    # Unchecked checkboxes are simply missing; make them explicit False.
    data = dict(data)
    for key in ("is_verified", "is_active"):
        data[key] = bool(data.get(key))
    return data


@admin_api
def api_facilities(request):
    if request.method == "GET":
        return _json({
            "facilities": [serialize_facility(f) for f in Facility.objects.order_by("name")],
            "types": [{"value": v, "label": l} for v, l in Facility.Type.choices],
        })

    if request.method != "POST":
        return _json({"error": "Method not allowed."}, 405)

    data = _body(request)
    if data is None:
        return _json({"error": "Invalid request."}, 400)
    form = FacilityForm(_form_data(data))
    if not form.is_valid():
        return _form_errors(form)
    return _json({"facility": serialize_facility(form.save())}, 201)


@admin_api
@require_POST
def api_facility_update(request, pk):
    try:
        facility = Facility.objects.get(pk=pk)
    except Facility.DoesNotExist:
        return _json({"error": "Facility not found."}, 404)

    data = _body(request)
    if data is None:
        return _json({"error": "Invalid request."}, 400)
    form = FacilityForm(_form_data(data), instance=facility)
    if not form.is_valid():
        return _form_errors(form)
    return _json({"facility": serialize_facility(form.save())})


@admin_api
@require_POST
def api_facility_delete(request, pk):
    deleted, _ = Facility.objects.filter(pk=pk).delete()
    if not deleted:
        return _json({"error": "Facility not found."}, 404)
    return _json({"ok": True})
