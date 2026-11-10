import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:muni_app/features/professional/professional_navigation.dart';
import 'package:muni_app/features/professional/screens/shared_assessment_screen.dart';
import 'package:muni_app/features/professional/widgets/pro_colors.dart';
import 'package:muni_app/features/professional/widgets/rise_in.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/features/professional/screens/professional_login_screen.dart';

class ScanShareScreen extends StatefulWidget {
  const ScanShareScreen({super.key});

  @override
  State<ScanShareScreen> createState() => _ScanShareScreenState();
}

class _ScanShareScreenState extends State<ScanShareScreen>
    with SingleTickerProviderStateMixin {
  static const double _size = 270;

  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  )..repeat(reverse: true);
  late final Animation<double> _sweepCurve =
      CurvedAnimation(parent: _sweep, curve: Curves.easeInOut);

  bool _handling = false;
  bool _found = false;
  bool _light = false;

  String get _status =>
      _found ? 'Code found. Opening check-in...' : 'Looking for a code...';

  @override
  void dispose() {
    _sweep.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    _handling = true;
    setState(() => _found = true);
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
    setState(() => _found = false);
    await _scanner.start();
  }

  Future<void> _close() async {
    final controller = context.read<ProfessionalController>();
    final navigator = Navigator.of(context);
    await controller.signOut();
    navigator.pushReplacement(MaterialPageRoute<void>(
      builder: (_) => const ProfessionalLoginScreen(),
    ));
  }

  Future<void> _toggleLight() async {
    try {
      await _scanner.toggleTorch();
      if (mounted) setState(() => _light = !_light);
    } catch (_) {
      // Device has no torch; ignore.
    }
  }

  Widget _corner({required bool top, required bool left}) {
    final inset = _found ? 8.0 : 0.0;
    final side = BorderSide(
      color: _found ? Colors.white : ProColors.fresh,
      width: 5,
    );
    const r = Radius.circular(34);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      top: top ? inset : null,
      bottom: top ? null : inset,
      left: left ? inset : null,
      right: left ? null : inset,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? r : Radius.zero,
            topRight: top && !left ? r : Radius.zero,
            bottomLeft: !top && left ? r : Radius.zero,
            bottomRight: !top && !left ? r : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _frame() {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: MobileScanner(controller: _scanner, onDetect: _onDetect),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  color: _found
                      ? ProColors.fresh.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          _corner(top: true, left: true),
          _corner(top: true, left: false),
          _corner(top: false, left: true),
          _corner(top: false, left: false),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _found ? 0 : 1,
                child: AnimatedBuilder(
                  animation: _sweepCurve,
                  builder: (context, _) => Align(
                    alignment: Alignment(0, -0.68 + 1.36 * _sweepCurve.value),
                    child: FractionallySizedBox(
                      widthFactor: 0.76,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: ProColors.fresh,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: const [
                            BoxShadow(color: ProColors.fresh, blurRadius: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutBack,
                  scale: _found ? 1 : 0,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ProColors.fresh,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProColors.night,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RiseIn(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Scan a MUNI code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _close,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                                color: Colors.white38, width: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RiseIn(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 310),
                      child: const Text(
                        'Ask the person to show their code, then point your '
                        'camera at it.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: const Alignment(0, -0.2),
                      child: RiseIn(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _frame(),
                            const SizedBox(height: 20),
                            Text(
                              _status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _toggleLight,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _light ? Colors.white : null,
                        foregroundColor:
                            _light ? ProColors.forest : Colors.white,
                        side: const BorderSide(color: Colors.white30, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _light ? 'Turn off light' : 'Turn on light',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'You can only open codes that the person chose to share.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: _light ? 1 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.16),
                      radius: 0.9,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}