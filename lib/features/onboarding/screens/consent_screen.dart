import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/services/consent_storage.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _understandsScreening = false;
  bool _understandsDataUse = false;
  bool _isAdult = false;
  bool _saving = false;

  bool get _allChecked =>
      _understandsScreening && _understandsDataUse && _isAdult;

  Future<void> _accept() async {
    final storage = context.read<ConsentStorage>();
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    await storage.recordConsent();
    if (!mounted) return;

    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  Widget _switch(String text, bool value, ValueChanged<bool> set) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MuniCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Switch(
              value: value,
              activeTrackColor: MuniColors.leaf,
              activeThumbColor: Colors.white,
              onChanged: (v) => setState(() => set(v)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: MuniColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MuniColors.mint,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: MuniColors.forest,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Before you begin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: MuniColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please confirm the following:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: MuniColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              _switch(
                'I understand that MUNI provides preliminary screening and '
                'general guidance, not a diagnosis.',
                _understandsScreening,
                (v) => _understandsScreening = v,
              ),
              _switch(
                'I understand that my questionnaire answers will be sent to '
                'the MUNI server to calculate my results.',
                _understandsDataUse,
                (v) => _understandsDataUse = v,
              ),
              _switch(
                'I am 18 years old or older.',
                _isAdult,
                (v) => _isAdult = v,
              ),
              const SizedBox(height: 4),
              const MuniCard(
                color: MuniColors.lav,
                child: Text(
                  'MUNI is currently designed for adults. If you are under '
                  '18, please talk to a parent, guardian, or school guidance '
                  'counselor, or call the crisis hotline.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: MuniColors.ink,
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => showCrisisSheet(context),
                  child: const Text(
                    'Need help right now?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: MuniColors.crisis,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can withdraw this consent at any time from '
                'About & privacy.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MuniColors.muted,
                ),
              ),
              const SizedBox(height: 24),
              MuniButton(
                label: _saving ? 'Saving...' : 'I agree & continue',
                onPressed: _allChecked && !_saving ? _accept : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}