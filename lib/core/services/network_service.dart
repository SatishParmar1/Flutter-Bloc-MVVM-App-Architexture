import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/logger.dart';

class NetworkService {
  NetworkService._();

  static final Connectivity _connectivity = Connectivity();
  
  static final StreamController<List<ConnectivityResult>> _connectivityController = 
      StreamController<List<ConnectivityResult>>.broadcast();

  static Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivityController.stream;

  static Future<void> initialize() async {
    try {
      _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _connectivityController.add(results);
        AppLogger.info('Network state changed: $results', tag: 'NetworkService');
      });
      AppLogger.success('NetworkService initialized successfully', tag: 'NetworkService');
    } catch (e) {
      AppLogger.error('Failed to initialize NetworkService', error: e, tag: 'NetworkService');
    }
  }

  static Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  static Future<List<ConnectivityResult>> currentConnectivity() async {
    return await _connectivity.checkConnectivity();
  }
}
