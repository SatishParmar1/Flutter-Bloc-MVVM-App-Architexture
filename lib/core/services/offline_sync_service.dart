import 'dart:convert';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../di/service_locator.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import '../config/app_config.dart';

class QueuedRequest {
  final String path;
  final String method;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final DateTime timestamp;

  QueuedRequest({
    required this.path,
    required this.method,
    this.data,
    this.queryParameters,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'method': method,
        'data': data,
        'queryParameters': queryParameters,
        'timestamp': timestamp.toIso8601String(),
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        path: json['path'] as String,
        method: json['method'] as String,
        data: json['data'],
        queryParameters: json['queryParameters'] != null
            ? Map<String, dynamic>.from(json['queryParameters'] as Map)
            : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class OfflineSyncService {
  OfflineSyncService._();

  static const String _queueKey = 'offline_requests_queue';
  static final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();
  static final Dio _syncDio = Dio(BaseOptions(baseUrl: AppConfig.instance.baseUrl));

  static bool _isSyncing = false;
  static bool get isSyncing => _isSyncing;

  static void initialize() {
    _connectionChecker.onStatusChange.listen((status) async {
      if (status == InternetConnectionStatus.connected) {
        AppLogger.success('Internet connection restored. Triggering auto-sync...', tag: 'OfflineSyncService');
        await syncPendingRequests();
      } else {
        AppLogger.warning('Device went offline.', tag: 'OfflineSyncService');
      }
    });
  }

  static Future<void> enqueueRequest({
    required String path,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final secureStorage = getIt<SecureStorage>();
      final queueList = await getPendingRequests();

      final newRequest = QueuedRequest(
        path: path,
        method: method,
        data: data,
        queryParameters: queryParameters,
        timestamp: DateTime.now(),
      );

      queueList.add(newRequest);

      final jsonString = jsonEncode(queueList.map((r) => r.toJson()).toList());
      await secureStorage.write(_queueKey, jsonString);

      AppLogger.warning('Request enqueued for background sync: $method $path', tag: 'OfflineSyncService');

      await NotificationService.showNotification(
        id: 300 + queueList.length,
        title: 'Offline Mode Active',
        body: 'Your changes have been saved locally. They will sync automatically once connection is restored.',
      );
    } catch (e, stack) {
      AppLogger.error('Failed to enqueue request', error: e, stackTrace: stack, tag: 'OfflineSyncService');
    }
  }

  static Future<List<QueuedRequest>> getPendingRequests() async {
    try {
      final secureStorage = getIt<SecureStorage>();
      final jsonString = await secureStorage.read(_queueKey);
      if (jsonString == null || jsonString.isEmpty) return [];

      final List<dynamic> decodedList = jsonDecode(jsonString) as List<dynamic>;
      return decodedList.map((item) => QueuedRequest.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.error('Failed to parse offline request queue', error: e, tag: 'OfflineSyncService');
      return [];
    }
  }

  static Future<void> syncPendingRequests() async {
    if (_isSyncing) return;

    final pending = await getPendingRequests();
    if (pending.isEmpty) return;

    _isSyncing = true;
    AppLogger.info('Starting sync process for ${pending.length} pending requests...', tag: 'OfflineSyncService');

    final secureStorage = getIt<SecureStorage>();
    final List<QueuedRequest> failedToSync = [];

    final token = await secureStorage.getAccessToken();
    if (token != null) {
      _syncDio.options.headers['Authorization'] = 'Bearer $token';
    }

    for (final request in pending) {
      try {
        AppLogger.info('Syncing request: ${request.method} ${request.path}', tag: 'OfflineSyncService');
        
        Response response;
        if (request.method.toUpperCase() == 'POST') {
          response = await _syncDio.post(request.path, data: request.data, queryParameters: request.queryParameters);
        } else if (request.method.toUpperCase() == 'PUT') {
          response = await _syncDio.put(request.path, data: request.data, queryParameters: request.queryParameters);
        } else if (request.method.toUpperCase() == 'DELETE') {
          response = await _syncDio.delete(request.path, data: request.data, queryParameters: request.queryParameters);
        } else {
          continue;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          AppLogger.success('Successfully synced request: ${request.path}', tag: 'OfflineSyncService');
          
          await NotificationService.showNotification(
            id: request.hashCode,
            title: 'Auto-Sync Completed',
            body: 'Changes to "${request.path}" successfully uploaded to server!',
          );
        } else {
          failedToSync.add(request);
        }
      } catch (e) {
        AppLogger.error('Failed to sync request: ${request.path}', error: e, tag: 'OfflineSyncService');
        failedToSync.add(request);
      }
    }

    if (failedToSync.isEmpty) {
      await secureStorage.delete(_queueKey);
      AppLogger.success('All pending requests successfully synchronized!', tag: 'OfflineSyncService');
      
      await NotificationService.showNotification(
        id: 999,
        title: 'Synchronization Finished',
        body: 'All local changes are now fully up to date with the server!',
      );
    } else {
      final jsonString = jsonEncode(failedToSync.map((r) => r.toJson()).toList());
      await secureStorage.write(_queueKey, jsonString);
    }

    _isSyncing = false;
  }

  static Future<bool> hasInternet() async {
    return await _connectionChecker.hasConnection;
  }
}
