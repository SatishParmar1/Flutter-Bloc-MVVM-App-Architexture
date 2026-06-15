import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../services/offline_sync_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  Dio get dio => _dio;

  ApiClient({required SecureStorage secureStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.instance.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      ConnectivityInterceptor(),
      AuthInterceptor(secureStorage: secureStorage),
      RetryInterceptor(dio: _dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    ]);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        await OfflineSyncService.enqueueRequest(
          path: path,
          method: 'POST',
          data: data,
          queryParameters: queryParameters,
        );
        return Response<T>(
          requestOptions: e.requestOptions,
          statusCode: 202,
          data: {
            'status': 'queued_offline',
            'message': 'Changes saved locally. Syncing in background when connection is restored.'
          } as T,
        );
      }
      rethrow;
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        await OfflineSyncService.enqueueRequest(
          path: path,
          method: 'PUT',
          data: data,
          queryParameters: queryParameters,
        );
        return Response<T>(
          requestOptions: e.requestOptions,
          statusCode: 202,
          data: {
            'status': 'queued_offline',
            'message': 'Changes saved locally. Syncing in background when connection is restored.'
          } as T,
        );
      }
      rethrow;
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        await OfflineSyncService.enqueueRequest(
          path: path,
          method: 'DELETE',
          data: data,
          queryParameters: queryParameters,
        );
        return Response<T>(
          requestOptions: e.requestOptions,
          statusCode: 202,
          data: {
            'status': 'queued_offline',
            'message': 'Changes saved locally. Syncing in background when connection is restored.'
          } as T,
        );
      }
      rethrow;
    }
  }

  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.message?.contains('Network') == true;
  }
}
