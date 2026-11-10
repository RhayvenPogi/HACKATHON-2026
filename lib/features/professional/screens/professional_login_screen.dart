import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/features/professional/screens/change_password_screen.dart';
import 'package:muni_app/features/professional/screens/scan_share_screen.dart';
import 'package:muni_app/features/professional/widgets/pro_colors.dart';
import 'package:muni_app/features/professional/widgets/rise_in.dart';

class ProfessionalLoginScreen extends StatefulWidget {
  const ProfessionalLoginScreen({super.key});

  @override
  State<ProfessionalLoginScreen> createState() =>
      _ProfessionalLoginScreenState();
}

class _ProfessionalLoginScreenState extends State<ProfessionalLoginScreen>
    with SingleTickerProviderStateMixin {
  final _username = TextEditingController();
  final _password = TextEditingController();
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  )..repeat(reverse: true);
  late final Animation<double> _floatCurve =
      CurvedAnimation(parent: _float, curve: Curves.easeInOut);

  String? _userErr;
  String? _passErr;
  bool _hidePassword = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _float.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = context.read<ProfessionalController>();
    final navigator = Navigator.of(context);
    setState(() {
      _userErr = null;
      _passErr = null;
    });

    var ok = true;
    if (_username.text.trim().isEmpty) {
      _userErr = 'Enter your username.';
      ok = false;
    }
    if (_password.text.isEmpty) {
      _passErr = 'Enter your password.';
      ok = false;
    }
    if (!ok) {
      setState(() {});
      return;
    }

    try {
      await controller.signIn(_username.text, _password.text);
      final mustChange = controller.session?.mustChangePassword ?? false;
      navigator.pushReplacement(MaterialPageRoute<void>(
        builder: (_) => mustChange
            ? const ChangePasswordScreen()
            : const ScanShareScreen(),
      ));
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() => _passErr =
          'Incorrect username or password, or your account is not authorized.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _passErr = error.userMessage);
    }
  }

  InputDecoration _decoration(String hint, {bool bad = false, Widget? suffix}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: 2),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: border(bad ? ProColors.crisis : const Color(0xFFDCEBE0)),
      focusedBorder: border(bad ? ProColors.crisis : ProColors.leaf),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 7),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: ProColors.ink,
          ),
        ),
      );

  Widget _err(String? text) => Container(
        constraints: const BoxConstraints(minHeight: 20),
        margin: const EdgeInsets.fromLTRB(2, 5, 2, 6),
        child: Text(
          text ?? '',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ProColors.crisis,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<ProfessionalController>().isBusy;

    return Scaffold(
      backgroundColor: ProColors.mint,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AutofillGroup(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 48, 22, 16),
                  children: [
                    AnimatedBuilder(
                      animation: _floatCurve,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, -8 * _floatCurve.value),
                        child: child,
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/img/muni-calm.png',
                          width: 112,
                          errorBuilder: (_, _, _) =>
                              const SizedBox(height: 112),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const RiseIn(
                      delay: Duration(milliseconds: 150),
                      child: Text(
                        'MUNI for\nProfessionals',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 31,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: ProColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const RiseIn(
                      delay: Duration(milliseconds: 220),
                      child: Text(
                        'Welcome back. Please log in to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ProColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    RiseIn(
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Username'),
                          TextField(
                            controller: _username,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            onChanged: (_) {
                              if (_userErr != null) {
                                setState(() => _userErr = null);
                              }
                            },
                            decoration: _decoration('Your username',
                                bad: _userErr != null),
                          ),
                          _err(_userErr),
                          _label('Password'),
                          TextField(
                            controller: _password,
                            obscureText: _hidePassword,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _submit(),
                            onChanged: (_) {
                              if (_passErr != null) {
                                setState(() => _passErr = null);
                              }
                            },
                            decoration: _decoration(
                              'Your password',
                              bad: _passErr != null,
                              suffix: IconButton(
                                tooltip: _hidePassword
                                    ? 'Show password'
                                    : 'Hide password',
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _hidePassword
                                      ? ProColors.muted
                                      : ProColors.forest,
                                ),
                                onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword),
                              ),
                            ),
                          ),
                          _err(_passErr),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: ProColors.leaf,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (busy) ...[
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Text(
                                    busy ? 'Logging in' : 'Log in',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Text(
                'Only approved professionals can log in.\n'
                'Need an account? Please contact the MUNI team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: ProColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}