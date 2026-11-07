import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/facilities/data/facility.dart';
import 'package:muni_app/features/facilities/data/facility_repository.dart';
import 'package:muni_app/features/facilities/widgets/facility_detail_card.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({
    super.key,
    this.repository = const SampleFacilityRepository(),
    this.showMapTiles = true,
  });

  final FacilityRepository repository;

  /// Tests set this to false to avoid network tile requests.
  final bool showMapTiles;

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  final MapController _mapController = MapController();
  late Future<List<Facility>> _facilities = widget.repository.getFacilities();
  String? _selectedId;

  void _select(Facility facility, {bool moveMap = true}) {
    setState(() => _selectedId = facility.id);
    if (moveMap) _mapController.move(facility.location, 16);
  }

  void _retry() {
    setState(() => _facilities = widget.repository.getFacilities());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a facility')),
      body: SafeArea(
        child: FutureBuilder<List<Facility>>(
          future: _facilities,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load facilities.'),
                    TextButton(onPressed: _retry, child: const Text('Try again')),
                  ],
                ),
              );
            }
            return _buildContent(context, snapshot.data ?? const []);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Facility> facilities) {
    final textTheme = Theme.of(context).textTheme;
    final bool hasSample = facilities.any((f) => f.isSample);
    final Facility? selected =
        facilities.where((f) => f.id == _selectedId).firstOrNull;

    return Column(
      children: [
        if (hasSample) const _SampleDataBanner(),
        Expanded(
          flex: 5,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: sanFernandoCityCenter,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              if (widget.showMapTiles)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.munihackathon.muni_app',
                ),
              MarkerLayer(
                markers: [
                  for (final f in facilities)
                    Marker(
                      point: f.location,
                      width: 44,
                      height: 44,
                      child: _FacilityMarker(
                        label: f.name,
                        selected: f.id == _selectedId,
                        onTap: () => _select(f, moveMap: false),
                      ),
                    ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.https('www.openstreetmap.org', '/copyright'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (selected != null) ...[
                FacilityDetailCard(facility: selected),
                const SizedBox(height: 16),
              ],
              Text('All facilities', style: textTheme.titleMedium),
              const SizedBox(height: 4),
              if (facilities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No facilities available yet.'),
                ),
              for (final f in facilities)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(f.name),
                  subtitle: Text(f.type),
                  selected: f.id == _selectedId,
                  onTap: () => _select(f),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SampleDataBanner extends StatelessWidget {
  const _SampleDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.error.withValues(alpha: 0.08),
      child: const Text(
        'SAMPLE DATA: these are not real facilities. Verified listings will '
        'replace them.',
        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FacilityMarker extends StatelessWidget {
  const _FacilityMarker({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(
          Icons.location_on,
          size: 44,
          color: selected ? AppColors.secondary : AppColors.primary,
        ),
      ),
    );
  }
}