import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/features/professional/screens/professional_home_screen.dart';
import 'package:muni_app/features/professional/screens/professional_login_screen.dart';
import 'package:muni_app/shared/widgets/app_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = context.read<ProfessionalController>();
    final navigator = Navigator.of(context);
    setState(() => _error = null);

    if (_next.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    if (_next.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    try {
      await controller.changePassword(_current.text, _next.text);
      navigator.pushReplacement(MaterialPageRoute<void>(
        builder: (_) => const ProfessionalHomeScreen(),
      ));
    } on ValidationException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.displayMessage);
    } on UnauthorizedException {
      navigator.pushReplacement(MaterialPageRoute<void>(
        builder: (_) => const ProfessionalLoginScreen(),
      ));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.userMessage);
    }
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          obscureText: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<ProfessionalController>().isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Set a new password',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Your account uses a temporary password from the administrator. '
              'Choose a new one that only you know before viewing shared '
              'assessments.',
            ),
            const SizedBox(height: 24),
            _field(_current, 'Current (temporary) password'),
            _field(_next, 'New password'),
            _field(_confirm, 'Confirm new password'),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            AppButton(
              label: 'Save new password',
              isLoading: busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}