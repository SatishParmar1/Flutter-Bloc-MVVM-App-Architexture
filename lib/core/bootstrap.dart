import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/app_bloc_observer.dart';
import 'di/service_locator.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/security_service.dart';
import 'services/network_service.dart';
import 'services/share_receiver_service.dart';
import 'services/offline_sync_service.dart';
import 'utils/confetti_manager.dart';
import '../app.dart';
import 'dart:developer' as developer;

Future<void> bootstrap() async {
  FlutterError.onError = (details) {
    developer.log(
      details.exceptionAsString(),
      name: 'FlutterError',
      stackTrace: details.stack,
      error: details.exception,
    );
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      
      await setupServiceLocator();
      
      // Initialize System Services
      await NotificationService.initialize();
      await BackgroundTaskService.initialize();
      await NetworkService.initialize();
      ShareReceiverService.initialize();
      OfflineSyncService.initialize();
      ConfettiManager.initialize();
      
      // Enable secure app protection by default
      await SecurityService.enableScreenshotProtection();
      
      Bloc.observer = AppBlocObserver();

      runApp(const App());
    },
    (error, stackTrace) {
      developer.log(
        'Uncaught error inside zone',
        name: 'ZoneError',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
