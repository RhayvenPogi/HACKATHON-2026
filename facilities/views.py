from django.http import JsonResponse
from django.views.decorators.http import require_GET

from .models import Facility


def public_facility(f):
    return {
        "id": str(f.id),
        "name": f.name,
        "type": f.get_facility_type_display(),
        "address": f.address,
        "latitude": float(f.latitude),
        "longitude": float(f.longitude),
        "phone": f.contact_number or None,
        "hours": f.hours or None,
        "source_note": f.source_note or None,
    }


@require_GET
def facility_list(request):
    """Public, read-only. Only verified and active facilities."""
    data = {"facilities": [public_facility(f) for f in Facility.objects.public()]}
    response = JsonResponse(data)
    response["Cache-Control"] = "public, max-age=300"
    return response
