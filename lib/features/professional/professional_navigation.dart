import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_exception.dart';
import 'package:muni_app/features/professional/data/share_qr_payload.dart';
import 'package:muni_app/features/professional/providers/professional_controller.dart';
import 'package:muni_app/features/professional/screens/change_password_screen.dart';
import 'package:muni_app/features/professional/screens/professional_home_screen.dart';
import 'package:muni_app/features/professional/screens/professional_login_screen.dart';
import 'package:muni_app/models/shared_assessment_view.dart';

/// Entry from citizen-side screens.
void openProfessionalArea(BuildContext context) {
  final s = context.read<ProfessionalController>().session;
  final Widget screen = s == null
      ? const ProfessionalLoginScreen()
      : (s.mustChangePassword
          ? const ChangePasswordScreen()
          : const ProfessionalHomeScreen());
  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
}

/// Parses a scanned or typed code and opens it. Shows errors itself.
/// Returns null on failure.
Future<SharedAssessmentView?> fetchSharedAssessment(
  BuildContext context,
  String raw,
) async {
  final controller = context.read<ProfessionalController>();
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  void show(String message) =>
      messenger.showSnackBar(SnackBar(content: Text(message)));

  final String token;
  try {
    token = ShareQrPayload.parse(raw);
  } on InvalidShareQr catch (error) {
    show(error.message);
    return null;
  }

  try {
    return await controller.openShare(token);
  } on ForbiddenException {
    show('Please change your temporary password first.');
    navigator.push(
      MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
    );
  } on UnauthorizedException catch (error) {
    show(error.userMessage);
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ProfessionalLoginScreen()),
    );
  } on ServerException catch (error) {
    show(error.statusCode == 404
        ? 'This code is invalid, expired, or no longer shared.'
        : error.userMessage);
  } on ApiException catch (error) {
    show(error.userMessage);
  }
  return null;
}