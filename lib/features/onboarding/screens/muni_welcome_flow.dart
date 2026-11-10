import 'package:flutter/material.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class MuniWelcomeFlow extends StatefulWidget {
  const MuniWelcomeFlow({super.key, required this.onGetStarted});

  /// Open your existing Terms / consent screen here.
  final VoidCallback onGetStarted;

  @override
  State<MuniWelcomeFlow> createState() => _MuniWelcomeFlowState();
}

class _MuniWelcomeFlowState extends State<MuniWelcomeFlow> {
  int _stage = 0; // 0 splash, 1 intro, 2 welcome

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2300), () {
      if (mounted) setState(() => _stage = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = switch (_stage) {
      0 => const _Splash(),
      1 => _Intro(onDone: () => setState(() => _stage = 2)),
      _ => _Welcome(onGetStarted: widget.onGetStarted),
    };
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: KeyedSubtree(key: ValueKey(_stage), child: page),
      ),
    );
  }
}

class _Hall extends StatelessWidget {
  const _Hall({this.faded = false});
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      'assets/img/cityhall.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
    if (!faded) return img;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
        stops: [0, 0.45],
      ).createShader(r),
      child: Opacity(opacity: 0.38, child: img),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        const Positioned(left: 0, right: 0, bottom: 0, child: _Hall()),
        Positioned(
          top: size.height * 0.14,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset(
              'assets/img/logo.png',
              width: size.width * 0.62,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Intro extends StatefulWidget {
  const _Intro({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> {
  static const _lines = [
    "I'm a little cloud with a sprout on my head.",
    "I'll keep you company while you check in on how you feel.",
    'No sign-up, no judgment. Just a small space for your mind.',
  ];
  int _step = 0;

  void _next() {
    if (_step < _lines.length - 1) {
      setState(() => _step++);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    return Stack(
      children: [
        const Positioned(left: 0, right: 0, bottom: 0, child: _Hall(faded: true)),
        Positioned(
          top: h * 0.11,
          left: 0,
          right: 0,
          child: const Text(
            "Hi, I'm Muni!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: MuniColors.forest,
            ),
          ),
        ),
        Positioned(
          top: h * 0.11 + 52,
          left: 34,
          right: 34,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Text(
              _lines[_step],
              key: ValueKey(_step),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: MuniColors.leaf,
              ),
            ),
          ),
        ),
        Positioned(
          top: h * 0.44,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _lines.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _step ? 26 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _step
                            ? MuniColors.forest
                            : const Color(0xFFCFE0D4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              MuniButton(
                label: _step == _lines.length - 1 ? "Let's go" : 'Next',
                expand: false,
                onPressed: _next,
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -26,
          left: size.width * 0.04,
          width: size.width * 0.92,
          child: Floating(
            amplitude: 8,
            duration: const Duration(milliseconds: 3600),
            child: Image.asset(
              'assets/img/muni-happy.png',
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Stack(
      children: [
        const Positioned(left: 0, right: 0, bottom: 0, child: _Hall(faded: true)),
        Positioned(
          top: h * 0.15,
          left: 0,
          right: 0,
          child: Floating(
            amplitude: 9,
            child: Center(
              child: Image.asset(
                'assets/img/muni-calm.png',
                width: 250,
                errorBuilder: (_, _, _) => const SizedBox(height: 250),
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MuniButton(
                    label: 'Get started',
                    large: true,
                    onPressed: onGetStarted,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No account needed. Your answers stay private.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MuniColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}