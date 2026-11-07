import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/constants/app_routes.dart';
import 'package:muni_app/core/services/consent_storage.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/shared/widgets/app_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Before you begin')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Please confirm the following:', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _understandsScreening,
                onChanged: (v) =>
                    setState(() => _understandsScreening = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I understand that FLOW provides preliminary screening and '
                  'general guidance, not a diagnosis.',
                ),
              ),
              CheckboxListTile(
                value: _understandsDataUse,
                onChanged: (v) =>
                    setState(() => _understandsDataUse = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I understand that my questionnaire answers will be sent to '
                  'the FLOW server to calculate my results.',
                ),
              ),
              CheckboxListTile(
                value: _isAdult,
                onChanged: (v) => setState(() => _isAdult = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('I am 18 years old or older.'),
              ),
              const SizedBox(height: 12),
              Text(
                'FLOW is currently designed for adults. If you are under 18, '
                'please talk to a parent, guardian, or school guidance '
                'counselor, or call the crisis hotline.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.crisisSupport),
                icon: const Icon(Icons.support_agent),
                label: const Text('Need help right now?'),
              ),
              const SizedBox(height: 16),
              Text(
                'You can withdraw this consent at any time from '
                'About & privacy.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'I agree and continue',
                isLoading: _saving,
                onPressed: _allChecked ? _accept : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}