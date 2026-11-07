import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:muni_app/features/professional/professional_navigation.dart';
import 'package:muni_app/features/professional/screens/shared_assessment_screen.dart';

class ScanShareScreen extends StatefulWidget {
  const ScanShareScreen({super.key});

  @override
  State<ScanShareScreen> createState() => _ScanShareScreenState();
}

class _ScanShareScreenState extends State<ScanShareScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handling = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    _handling = true;
    await _scanner.stop();
    if (!mounted) return;

    final view = await fetchSharedAssessment(context, raw);
    if (!mounted) return;

    if (view != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SharedAssessmentScreen(view: view),
        ),
      );
      return;
    }
    _handling = false;
    await _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan share code')),
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Point the camera at the citizen's Muni QR code.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}