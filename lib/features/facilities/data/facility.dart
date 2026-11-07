import 'package:latlong2/latlong.dart';

class Facility {
  const Facility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.location,
    required this.isSample,
    this.phone,
    this.hours,
    this.sourceNote,
  });

  final String id;
  final String name;
  final String type;
  final String address;
  final LatLng location;

  /// True for UI-development placeholders. Never true for real listings.
  final bool isSample;

  /// Only from a verified source. Never guessed.
  final String? phone;
  final String? hours;

  /// Where this listing came from and when it was verified,
  /// e.g. "City Health Office list, verified 2026-11-20".
  final String? sourceNote;
}