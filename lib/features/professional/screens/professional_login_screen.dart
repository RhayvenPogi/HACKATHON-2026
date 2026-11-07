import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/core/theme/app_colors.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/features/professional/screens/change_password_screen.dart';
import 'package:muni_app/features/professional/screens/professional_home_screen.dart';
import 'package:muni_app/shared/widgets/app_button.dart';

class ProfessionalLoginScreen extends StatefulWidget {
  const ProfessionalLoginScreen({super.key});

  @override
  State<ProfessionalLoginScreen> createState() =>
      _ProfessionalLoginScreenState();
}

class _ProfessionalLoginScreenState extends State<ProfessionalLoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = context.read<ProfessionalController>();
    final navigator = Navigator.of(context);
    setState(() => _error = null);

    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your username and password.');
      return;
    }
    try {
      await controller.signIn(_username.text, _password.text);
      final mustChange = controller.session?.mustChangePassword ?? false;
      navigator.pushReplacement(MaterialPageRoute<void>(
        builder: (_) => mustChange
            ? const ChangePasswordScreen()
            : const ProfessionalHomeScreen(),
      ));
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() => _error =
          'Incorrect username or password, or your account is not authorized.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.userMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final busy = context.watch<ProfessionalController>().isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Professional sign in')),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('For registered mental health professionals',
                  style: textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Accounts are created by the Muni administrator. Citizens do '
                'not need to sign in.',
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _username,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              AppButton(label: 'Sign in', isLoading: busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}