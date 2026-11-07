/// Strict JSON readers. Error messages name fields, never values,
/// so no assessment data can leak into logs.
Map<String, dynamic> requireMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Expected object at "$key".');
}

int requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('Expected integer at "$key".');
}

String requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) return value;
  throw FormatException('Expected string at "$key".');
}