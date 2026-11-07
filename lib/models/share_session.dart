import 'package:muni_app/models/json_utils.dart';

/// What the phone keeps about an active share: token, link, expiry.
/// NEVER add scores or answers to this class.
class ShareSession {
  const ShareSession({
    required this.token,
    required this.shareUrl,
    required this.expiresAt,
    required this.isDemo,
  });

  factory ShareSession.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.tryParse(requireString(json, 'expires_at'));
    if (expiresAt == null) {
      throw const FormatException('Invalid "expires_at".');
    }
    return ShareSession(
      token: requireString(json, 'token'),
      shareUrl: requireString(json, 'share_url'),
      expiresAt: expiresAt,
      isDemo: json['is_demo'] == true,
    );
  }

  final String token;
  final String shareUrl;
  final DateTime expiresAt;
  final bool isDemo;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  Map<String, dynamic> toJson() => {
        'token': token,
        'share_url': shareUrl,
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'is_demo': isDemo,
      };
}