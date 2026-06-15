import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage.dart';
import '../di/service_locator.dart';

class AuthGuard {
  AuthGuard._();

  static Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final secureStorage = getIt<SecureStorage>();
    final token = await secureStorage.getAccessToken();
    final isLoggingIn = state.matchedLocation == '/login';

    if (token == null) {
      if (!isLoggingIn) {
        return '/login';
      }
    } else {
      if (isLoggingIn) {
        return '/';
      }
    }

    return null;
  }
}
