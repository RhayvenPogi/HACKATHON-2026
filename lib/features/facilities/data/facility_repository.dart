import 'package:latlong2/latlong.dart';
import 'package:muni_app/features/facilities/data/facility.dart';

/// Approximate center of San Fernando City, La Union.
final LatLng sanFernandoCityCenter = LatLng(16.6159, 120.3166);

abstract interface class FacilityRepository {
  Future<List<Facility>> getFacilities();
}

/// SAMPLE DATA ONLY. Fictional facilities for UI development.
/// Replace with verified data via a backend endpoint
/// (planned: GET /api/facilities/) and an ApiFacilityRepository.
class SampleFacilityRepository implements FacilityRepository {
  const SampleFacilityRepository();

  @override
  Future<List<Facility>> getFacilities() async {
    return [
      Facility(
        id: 'sample-a',
        name: 'Sample Facility A',
        type: 'Sample: hospital outpatient mental health unit',
        address: 'Sample address, San Fernando City (not a real location)',
        location: LatLng(16.6185, 120.3210),
        isSample: true,
      ),
      Facility(
        id: 'sample-b',
        name: 'Sample Facility B',
        type: 'Sample: community mental health clinic',
        address: 'Sample address, San Fernando City (not a real location)',
        location: LatLng(16.6120, 120.3245),
        isSample: true,
      ),
      Facility(
        id: 'sample-c',
        name: 'Sample Facility C',
        type: 'Sample: counseling and wellness center',
        address: 'Sample address, San Fernando City (not a real location)',
        location: LatLng(16.6230, 120.3275),
        isSample: true,
      ),
    ];
  }
}