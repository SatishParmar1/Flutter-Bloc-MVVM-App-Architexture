import 'package:dio/dio.dart';
import 'failures.dart';
import '../utils/toast_manager.dart';

class ExceptionMapper {
  ExceptionMapper._();

  static AppFailure map(Object error) {
    AppFailure failure;

    if (error is AppFailure) {
      failure = error;
    } else if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          failure = const NetworkFailure(message: 'Connection timed out');
          break;
        case DioExceptionType.connectionError:
          failure = const NetworkFailure(message: 'No internet connection');
          break;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['message'] as String? ?? 'Server error';
          if (statusCode == 401 || statusCode == 403) {
            failure = AuthFailure(message: message);
          } else {
            failure = ServerFailure(message: message, statusCode: statusCode);
          }
          break;
        case DioExceptionType.cancel:
          failure = const UnknownFailure(message: 'Request cancelled');
          break;
        default:
          failure = const UnknownFailure(message: 'Unexpected network error occurred');
          break;
      }
    } else {
      failure = UnknownFailure(message: error.toString());
    }

    // Automatically trigger our gorgeous, sliding 2-line error toast!
    ToastManager.showError(failure.message);
    return failure;
  }
}
