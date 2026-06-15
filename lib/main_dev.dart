import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setConfiguration(
    AppConfig(
      flavor: AppFlavor.dev,
      appName: 'App [DEV]',
      baseUrl: 'https://dev-api.example.com',
    ),
  );
  await bootstrap();
}
