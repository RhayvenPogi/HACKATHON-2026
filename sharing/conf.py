from datetime import timedelta

from django.conf import settings


def share_ttl():
    return getattr(settings, "MUNI_SHARE_TTL", timedelta(days=15))


def session_ttl():
    return getattr(settings, "MUNI_PROFESSIONAL_SESSION_TTL", timedelta(hours=12))


def share_url_prefix():
    return getattr(settings, "MUNI_SHARE_URL_PREFIX", "muni://share/")