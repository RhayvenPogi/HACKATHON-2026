import 'package:flutter/material.dart';
import 'package:muni_app/features/onboarding/data/terms_data.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

/// Resolves true when the person confirms 18+ and taps "I agree & continue".
Future<bool?> showTermsSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MuniColors.forest,
    barrierColor: const Color(0x5914281E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.9,
      child: const _TermsBody(),
    ),
  );
}

class _TermsBody extends StatefulWidget {
  const _TermsBody();

  @override
  State<_TermsBody> createState() => _TermsBodyState();
}

class _TermsBodyState extends State<_TermsBody> {
  bool _isAdult = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 14, 4, 12),
            child: Column(
              children: [
                Text(
                  'Terms and Conditions & User Consent',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'A Little Space for Your Mind.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: MuniColors.fresh,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        termsLead[0],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(termsLead[1], style: _body),
                    ],
                  ),
                ),
                for (var i = 0; i < termsSections.length; i++)
                  _Accordion(
                    number: i + 1,
                    section: termsSections[i],
                    initiallyOpen: i == 0,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                  child: Column(
                    children: [
                      Text(termsEnd[0],
                          textAlign: TextAlign.center,
                          style: _body.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(termsEnd[1],
                          textAlign: TextAlign.center,
                          style: _body.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        termsEnd[2],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: MuniColors.fresh,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    value: _isAdult,
                    onChanged: (v) => setState(() => _isAdult = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: Colors.white,
                    checkColor: MuniColors.forest,
                    side: const BorderSide(color: Colors.white, width: 2),
                    title: const Text(
                      'I am 18 years old or older.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: const Text(
                      'If you are under 18, please talk to a parent, '
                      'guardian, or school guidance counselor.',
                      style: TextStyle(fontSize: 12, color: Color(0xCCFFFFFF)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    enabled: _isAdult,
                    child: IgnorePointer(
                      ignoring: !_isAdult,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isAdult ? 1 : 0.45,
                        child: MuniButton(
                          label: 'I agree & continue',
                          variant: MuniButtonVariant.light,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.35),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _body = TextStyle(
  fontSize: 14,
  height: 1.5,
  fontWeight: FontWeight.w600,
  color: Color(0xE6FFFFFF),
);

class _Accordion extends StatefulWidget {
  const _Accordion({
    required this.number,
    required this.section,
    required this.initiallyOpen,
  });

  final int number;
  final TermsSection section;
  final bool initiallyOpen;

  @override
  State<_Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<_Accordion> {
  late bool _open = widget.initiallyOpen;

  Widget _block(TermsBlock b) {
    if (b.paragraph != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(b.paragraph!, style: _body),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          for (final item in b.bullets!)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 7, left: 2, right: 11),
                    decoration: const BoxDecoration(
                      color: MuniColors.fresh,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(child: Text(item, style: _body)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _open ? 0.15 : 0.09),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.number}. ${widget.section.title}',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final b in widget.section.blocks) _block(b),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}