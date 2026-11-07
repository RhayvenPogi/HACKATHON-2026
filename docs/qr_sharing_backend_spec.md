# QR Sharing — Backend Specification (NOT YET IMPLEMENTED)

Flutter client is built against this contract and ships in demo mode until
these endpoints exist (enable with --dart-define=SHARE_API_ENABLED=true).

Prerequisite: `professionals` app (admin module) is in place.

## Models (new app: `sharing`)

**SharedAssessment**
- id (UUID), responses (JSON, 42 ints), depression/anxiety/stress score + severity
- scoring_version, consent_version, consent_given_at, created_at
- NO name, device ID, IP address, or other identifiers

**ShareToken**
- token_hash (CharField 64, unique) — SHA-256 of the raw token. Raw token is NEVER stored or logged.
- assessment (FK → SharedAssessment). Deleting a token must NOT delete the assessment.
- created_at, expires_at (= created_at + 15 days), revoked_at (nullable)

**ShareAccessLog**
- assessment (FK), professional (FK → professionals.Professional), accessed_at

None of these models may be registered in Django admin
(enforced by `professionals.tests.AdminScopeTests`).

## Endpoints

### POST /api/shares/   (AllowAny + throttling)
Request: `{"responses": [42 ints 0–3], "consent_version": 1, "consent_given": true}`
- Validate exactly as /api/assessments/. Reject if consent_given is not true.
- RE-SCORE server-side. Never accept scores from the client.
- raw = secrets.token_urlsafe(32); store sha256(raw).
Response 201: `{"token": raw, "share_url": "<SHARE_BASE_URL>/s/<raw>/", "expires_at": "<ISO 8601 UTC>"}`

### DELETE /api/shares/<token>/
- Possession of the token authorizes revocation (citizens have no accounts).
- Sets revoked_at (or deletes the token). 204 on success; 404 if unknown/expired/revoked.

### GET /s/<token>/   (professional web view)
- Login required. Professional must satisfy `can_receive_shared_assessments`.
- Token must exist, not be revoked, and `now < expires_at` — checked on EVERY request.
- Shows answers, scores, severities, and the screening notice. Writes a ShareAccessLog row.
- Headers: `Cache-Control: no-store`, `Referrer-Policy: no-referrer`.

## Expiry
- Validity is enforced at request time (above). Cleanup is housekeeping only.
- Management command `purge_expired_shares`: deletes expired/revoked ShareTokens.
  Never deletes SharedAssessment. Run daily (Windows Task Scheduler / cron).

## Logging
- Request logs include URL paths, so /s/<token>/ and /api/shares/<token>/ leak tokens.
  Redact these paths in production logging.

## Open decisions (team / adviser)
1. Retention period for SharedAssessment after its token is deleted (Data Privacy Act 2012).
2. Whether professionals see item-level answers or scores only (consent text must match).
3. SHARE_BASE_URL must be reachable from the professional's device (LAN IP or deployed host).
4. HTTPS is mandatory before any real citizen data is shared.