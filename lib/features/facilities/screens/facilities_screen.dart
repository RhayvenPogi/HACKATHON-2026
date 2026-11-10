import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muni_app/features/facilities/data/facility.dart';
import 'package:muni_app/features/facilities/data/facility_repository.dart';
import 'package:muni_app/features/facilities/widgets/facility_detail_card.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({
    super.key,
    this.repository = const SampleFacilityRepository(),
    this.showMapTiles = true,
    this.embedded = false,
  });

  final FacilityRepository repository;

  /// Tests set this to false to avoid network tile requests.
  final bool showMapTiles;

  /// True when shown as a tab in HomeScreen: no app bar, no back button.
  final bool embedded;

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  final MapController _mapController = MapController();
  late Future<List<Facility>> _facilities = widget.repository.getFacilities();
  String? _selectedId;
  String _query = '';
  String _type = 'All';

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
      backgroundColor: MuniColors.mint,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: MuniColors.forest,
            ),
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
                    TextButton(
                        onPressed: _retry, child: const Text('Try again')),
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

  Widget _chip(String label) {
    final on = _type == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _type = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: on ? MuniColors.leaf : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: on ? MuniColors.leaf : MuniColors.line,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: on ? Colors.white : MuniColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Facility> all) {
    final bool hasSample = all.any((f) => f.isSample);
    final types = <String>{for (final f in all) f.type}.toList()..sort();
    final q = _query.toLowerCase();
    final facilities = all
        .where((f) =>
            (_type == 'All' || f.type == _type) &&
            f.name.toLowerCase().contains(q))
        .toList();
    final Facility? selected =
        facilities.where((f) => f.id == _selectedId).firstOrNull;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, widget.embedded ? 24 : 0, 20, 28),
      children: [
        const Text(
          'Find Help Near You',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: MuniColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search a place or area',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: MuniColors.line, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(color: MuniColors.leaf, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [_chip('All'), for (final t in types) _chip(t)]),
        ),
        const SizedBox(height: 14),
        if (hasSample)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MuniColors.crisis.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'SAMPLE DATA: these are not real facilities. Verified listings '
              'will replace them.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MuniColors.crisis,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: 240,
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
        ),
        const SizedBox(height: 14),
        if (selected != null) ...[
          FacilityDetailCard(facility: selected),
          const SizedBox(height: 14),
        ],
        if (facilities.isEmpty)
          const MuniCard(
            child: Text(
              'No places found. Try another name or choose All.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: MuniColors.muted,
              ),
            ),
          ),
        for (final f in facilities)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: f.id == _selectedId ? MuniColors.chip : Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _select(f),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          color: MuniColors.leaf),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: MuniColors.ink,
                              ),
                            ),
                            Text(
                              f.type,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MuniColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
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
        child: AnimatedScale(
          duration: const Duration(milliseconds: 300),
          scale: selected ? 1.3 : 1,
          child: Icon(
            Icons.location_on,
            size: 44,
            color: selected ? const Color(0xFF4A5BA8) : MuniColors.leaf,
          ),
        ),
      ),
    );
  }
}