import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 1000),
  }) : _dio = dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    var retries = err.requestOptions.extra['retries'] as int? ?? 0;

    if (_shouldRetry(err) && retries < maxRetries) {
      retries++;
      err.requestOptions.extra['retries'] = retries;

      final delay = initialDelay * (1 << (retries - 1));
      await Future.delayed(delay);

      try {
        final response = await _dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException) {
          return super.onError(e, handler);
        }
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.type == DioExceptionType.unknown && err.error is SocketException);
  }
}
