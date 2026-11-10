import json
import secrets
from datetime import timedelta
from functools import wraps

from django.contrib.auth import authenticate, login, logout, update_session_auth_hash
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Count
from django.db.models.functions import TruncDate
from django.http import JsonResponse
from django.shortcuts import render
from django.utils import timezone
from django.views.decorators.csrf import ensure_csrf_cookie
from django.views.decorators.http import require_GET, require_POST

from professionals.models import Professional
from sharing.models import ProfessionalSession

from .forms import PortalRegistrationForm

ADMIN_PERM = "professionals.change_professional"
V = Professional.Verification


# ---------- helpers ----------

def is_portal_admin(user):
    return (
        user.is_authenticated
        and user.is_active
        and user.is_staff
        and user.has_perm(ADMIN_PERM)
    )


def _json(data, status=200):
    response = JsonResponse(data, status=status)
    response["Cache-Control"] = "no-store"
    return response


def _body(request):
    try:
        data = json.loads(request.body or b"{}")
    except (json.JSONDecodeError, UnicodeDecodeError):
        return None
    return data if isinstance(data, dict) else None


def admin_api(view):
    @wraps(view)
    def wrapper(request, *args, **kwargs):
        if not is_portal_admin(request.user):
            return _json({"error": "Please sign in."}, 401)
        return view(request, *args, **kwargs)

    return wrapper


def _me(user):
    name = user.get_full_name().strip() or user.username
    initials = "".join(w[0] for w in name.split()[:2]).upper() or "A"
    return {
        "name": name,
        "username": user.username,
        "initials": initials,
        "professions": [
            {"value": value, "label": label}
            for value, label in Professional.Profession.choices
        ],
    }


def portal_status(p):
    if p.verification_status == V.PENDING:
        return "pending"
    if p.verification_status == V.REJECTED:
        return "rejected"
    return "verified" if p.is_active else "deactivated"


def serialize(p):
    return {
        "id": str(p.id),
        "name": p.full_name,
        "username": p.user.username,
        "lic": p.prc_license_number,
        "expiry": p.prc_license_expiry.isoformat(),
        "license_current": p.license_is_current,
        "type": p.get_profession_display(),
        "fac": p.facility_name,
        "email": p.contact_email,
        "phone": p.contact_number,
        "date": timezone.localtime(p.created_at).date().isoformat(),
        "status": portal_status(p),
        "must_change_password": p.must_change_password,
    }


def _issue_temporary_password(p):
    temporary = secrets.token_urlsafe(9)
    p.user.set_password(temporary)
    p.must_change_password = True
    return temporary


def _revoke_sessions(p):
    ProfessionalSession.objects.valid().filter(professional=p).update(
        revoked_at=timezone.now()
    )


# ---------- page ----------

@require_GET
@ensure_csrf_cookie
def index(request):
    return render(request, "portal/index.html")


# ---------- auth ----------

@require_POST
def api_login(request):
    data = _body(request) or {}
    user = authenticate(
        request,
        username=str(data.get("username", "")).strip(),
        password=str(data.get("password", "")),
    )
    if user is None or not is_portal_admin(user):
        return _json(
            {"error": "Incorrect username or password, or this account is not an administrator."},
            401,
        )
    login(request, user)
    if not data.get("remember"):
        request.session.set_expiry(0)  # ends when the browser closes
    return _json(_me(user))


@require_POST
def api_logout(request):
    logout(request)
    return _json({"ok": True})


@require_GET
@admin_api
def api_me(request):
    return _json(_me(request.user))


# ---------- dashboard (no citizen data) ----------

@admin_api
@require_GET
def api_dashboard(request):
    try:
        days = int(request.GET.get("range", 30))
    except ValueError:
        days = 30
    if days not in (7, 30, 90):
        days = 30

    today = timezone.localdate()
    start = today - timedelta(days=days - 1)
    daily = {
        row["day"]: row["n"]
        for row in Professional.objects.filter(created_at__date__gte=start)
        .annotate(day=TruncDate("created_at"))
        .values("day")
        .annotate(n=Count("id"))
        .order_by()
    }

    bucket = 1 if days <= 30 else 7
    labels, values = [], []
    day = start
    while day <= today:
        end = min(day + timedelta(days=bucket - 1), today)
        span = (end - day).days + 1
        labels.append(day.isoformat())
        values.append(sum(daily.get(day + timedelta(days=i), 0) for i in range(span)))
        day = end + timedelta(days=1)

    names = dict(Professional.Profession.choices)
    active = Professional.objects.filter(verification_status=V.VERIFIED, is_active=True)
    professions = [
        {"label": names.get(r["profession"], r["profession"]), "count": r["n"]}
        for r in active.values("profession").annotate(n=Count("id")).order_by("-n")
    ]
    expiring_soon = active.filter(
        prc_license_expiry__lte=today + timedelta(days=60)
    ).count()

    return _json({
        "activity": {"labels": labels, "values": values, "bucket_days": bucket},
        "professions": professions,
        "expiring_soon": expiring_soon,
    })


# ---------- professionals ----------

@admin_api
def api_professionals(request):
    if request.method == "GET":
        qs = Professional.objects.select_related("user").order_by("-created_at")
        return _json({"professionals": [serialize(p) for p in qs]})

    if request.method != "POST":
        return _json({"error": "Method not allowed."}, 405)

    data = _body(request)
    if data is None:
        return _json({"error": "Invalid request."}, 400)

    form = PortalRegistrationForm(data)
    if not form.is_valid():
        return _json(
            {
                "error": "Please correct the fields below.",
                "fields": {k: [str(m) for m in v] for k, v in form.errors.items()},
            },
            400,
        )
    with transaction.atomic():
        professional = form.save()
    return _json({"professional": serialize(professional)}, 201)


ALLOWED = {
    "approve": {"pending"},
    "reject": {"pending"},
    "reopen": {"rejected"},
    "deactivate": {"verified"},
    "reset_password": {"verified"},
    "activate": {"deactivated"},
}


@admin_api
@require_POST
def api_professional_action(request, pk):
    data = _body(request) or {}
    action = data.get("action")
    if action not in ALLOWED:
        return _json({"error": "Unknown action."}, 400)

    try:
        p = Professional.objects.select_related("user").get(pk=pk)
    except Professional.DoesNotExist:
        return _json({"error": "Professional not found."}, 404)

    status = portal_status(p)
    if status not in ALLOWED[action]:
        return _json({"error": f"This action is not available for a {status} professional."}, 409)

    if action == "approve":
        if data.get("checklist") is not True:
            return _json({"error": "Confirm all verification checks before approving."}, 400)
        if not p.license_is_current:
            return _json({"error": "The PRC license has expired. Update it before approving."}, 400)

    temporary = None
    with transaction.atomic():
        if action == "approve":
            temporary = _issue_temporary_password(p)
            p.verification_status = V.VERIFIED
            p.is_active = True
            p.user.is_active = True
        elif action == "reject":
            p.verification_status = V.REJECTED
        elif action == "reopen":
            p.verification_status = V.PENDING
        elif action == "deactivate":
            p.is_active = False
            p.user.is_active = False
            _revoke_sessions(p)
        elif action == "activate":
            p.is_active = True
            p.user.is_active = True
        elif action == "reset_password":
            temporary = _issue_temporary_password(p)
            _revoke_sessions(p)
        p.user.save()
        p.save()

    payload = {"professional": serialize(p)}
    if temporary:
        payload["temporary_password"] = temporary
    return _json(payload)


# ---------- account settings ----------

@admin_api
@require_POST
def api_settings(request):
    data = _body(request) or {}
    user = request.user
    name = str(data.get("display_name", "")).strip()[:150]
    current = str(data.get("current_password", ""))
    new = str(data.get("new_password", ""))
    confirm = str(data.get("confirm_password", ""))

    if new or confirm:
        if not user.check_password(current):
            return _json({"error": "Password not changed.",
                          "fields": {"current_password": ["Current password is incorrect."]}}, 400)
        if new != confirm:
            return _json({"error": "Password not changed.",
                          "fields": {"confirm_password": ["Passwords do not match."]}}, 400)
        try:
            validate_password(new, user)
        except ValidationError as error:
            return _json({"error": "Password not changed.",
                          "fields": {"new_password": list(error.messages)}}, 400)
        user.set_password(new)

    if name:
        user.first_name, user.last_name = name, ""
    user.save()
    if new:
        update_session_auth_hash(request, user)  # stay signed in
    return _json(_me(user))
