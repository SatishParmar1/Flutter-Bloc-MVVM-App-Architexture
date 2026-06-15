import 'package:workmanager/workmanager.dart';
import '../utils/logger.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      AppLogger.info('Executing background task: $taskName', tag: 'BackgroundTaskService');

      if (taskName == BackgroundTaskService.syncTaskName) {
        await NotificationService.showNotification(
          id: 999,
          title: 'Background Sync Active',
          body: 'Data synchronization task executed successfully in the background!',
        );
      }
      return true;
    } catch (e, stack) {
      AppLogger.error('Background task failed: $taskName', error: e, stackTrace: stack, tag: 'BackgroundTaskService');
      return false;
    }
  });
}

class BackgroundTaskService {
  BackgroundTaskService._();

  static const String syncTaskName = 'com.example.app.backgroundSync';

  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      AppLogger.success('BackgroundTaskService initialized successfully', tag: 'BackgroundTaskService');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize BackgroundTaskService', error: e, stackTrace: stack, tag: 'BackgroundTaskService');
    }
  }

  static Future<void> registerPeriodicSyncTask() async {
    try {
      await Workmanager().registerPeriodicTask(
        syncTaskName,
        syncTaskName,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
      AppLogger.success('Periodic background sync registered successfully', tag: 'BackgroundTaskService');
    } catch (e) {
      AppLogger.error('Failed to register periodic background task', error: e, tag: 'BackgroundTaskService');
    }
  }

  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}
