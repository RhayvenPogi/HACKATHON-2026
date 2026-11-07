import 'package:flutter/material.dart';
import 'package:muni_app/app.dart';
import 'package:muni_app/core/services/consent_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final consentStorage = await ConsentStorage.create();
  runApp(MuniApp(consentStorage: consentStorage));
}