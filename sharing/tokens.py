import hashlib
import secrets


def generate_token() -> str:
    """256 bits of randomness, URL-safe. Never store or log the raw value."""
    return secrets.token_urlsafe(32)


def hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()