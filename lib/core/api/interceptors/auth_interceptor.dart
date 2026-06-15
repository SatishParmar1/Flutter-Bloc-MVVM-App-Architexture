import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';
import '../../config/app_config.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _refreshDio;

  AuthInterceptor({
    required SecureStorage secureStorage,
  })  : _secureStorage = secureStorage,
        _refreshDio = Dio(BaseOptions(baseUrl: AppConfig.instance.baseUrl));

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path != ApiEndpoints.login && options.path != ApiEndpoints.refreshToken) {
      final token = await _secureStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiEndpoints.login &&
        err.requestOptions.path != ApiEndpoints.refreshToken) {
      
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null) {
          final response = await _refreshDio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final newAccessToken = response.data['accessToken'] as String?;
            final newRefreshToken = response.data['refreshToken'] as String?;

            if (newAccessToken != null) {
              await _secureStorage.saveAccessToken(newAccessToken);
              if (newRefreshToken != null) {
                await _secureStorage.saveRefreshToken(newRefreshToken);
              }

              final options = err.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';

              final retryDio = Dio(BaseOptions(baseUrl: AppConfig.instance.baseUrl));
              final retryResponse = await retryDio.fetch(options);
              return handler.resolve(retryResponse);
            }
          }
        }
      } catch (e) {
        await _secureStorage.deleteAccessToken();
        await _secureStorage.deleteRefreshToken();
      }
    }

    return handler.next(err);
  }
}
