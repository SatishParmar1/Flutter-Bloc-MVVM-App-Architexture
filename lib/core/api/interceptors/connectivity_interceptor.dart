import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class ConnectivityInterceptor extends Interceptor {
  final Connectivity _connectivity;

  ConnectivityInterceptor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'No active internet connection',
        ),
      );
    }
    return handler.next(options);
  }
}
