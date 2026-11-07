import 'package:muni_app/models/json_utils.dart';

class ProfessionalSession {
  const ProfessionalSession({
    required this.token,
    required this.expiresAt,
    required this.fullName,
    required this.profession,
    required this.mustChangePassword,
  });

  factory ProfessionalSession.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.tryParse(requireString(json, 'expires_at')) ??
        (throw const FormatException('Invalid "expires_at".'));
    final professional = requireMap(json, 'professional');
    return ProfessionalSession(
      token: requireString(json, 'token'),
      expiresAt: expiresAt,
      fullName: requireString(professional, 'full_name'),
      profession: requireString(professional, 'profession'),
      mustChangePassword: json['must_change_password'] == true,
    );
  }

  final String token;
  final DateTime expiresAt;
  final String fullName;
  final String profession;
  final bool mustChangePassword;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  ProfessionalSession copyWith({bool? mustChangePassword}) => ProfessionalSession(
        token: token,
        expiresAt: expiresAt,
        fullName: fullName,
        profession: profession,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'professional': {'full_name': fullName, 'profession': profession},
        'must_change_password': mustChangePassword,
      };
}