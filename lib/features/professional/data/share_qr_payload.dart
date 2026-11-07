class InvalidShareQr implements Exception {
  const InvalidShareQr(this.message);

  final String message;
}

/// Accepts `muni://share/<token>` (from a QR) or a bare token (manual entry).
abstract final class ShareQrPayload {
  static final RegExp _token = RegExp(r'^[A-Za-z0-9_-]{20,128}$');

  /// Returns the share token, or throws [InvalidShareQr].
  static String parse(String raw) {
    final value = raw.trim();
    if (_token.hasMatch(value)) return value;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.host == 'demo.invalid') {
      throw const InvalidShareQr(
        'This is a demo QR code. Ask the citizen to share again from the '
        'live app.',
      );
    }
    if (uri == null ||
        uri.scheme != 'muni' ||
        uri.host != 'share' ||
        uri.pathSegments.length != 1 ||
        !_token.hasMatch(uri.pathSegments.single)) {
      throw const InvalidShareQr('This is not a Muni share code.');
    }
    return uri.pathSegments.single;
  }
}