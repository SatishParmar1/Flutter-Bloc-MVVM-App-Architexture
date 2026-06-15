import 'package:local_auth/local_auth.dart';
import 'package:screen_protector/screen_protector.dart';
import '../utils/logger.dart';

class SecurityService {
  SecurityService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<void> enableScreenshotProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      AppLogger.success('Screenshot protection enabled', tag: 'SecurityService');
    } catch (e) {
      AppLogger.error('Failed to enable screenshot protection', error: e, tag: 'SecurityService');
    }
  }

  static Future<void> disableScreenshotProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      AppLogger.success('Screenshot protection disabled', tag: 'SecurityService');
    } catch (e) {
      AppLogger.error('Failed to disable screenshot protection', error: e, tag: 'SecurityService');
    }
  }

  static Future<bool> canUseBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (e) {
      AppLogger.error('Error checking biometrics availability', error: e, tag: 'SecurityService');
      return false;
    }
  }

  static Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (authenticated) {
        AppLogger.success('Authentication successful', tag: 'SecurityService');
      } else {
        AppLogger.warning('Authentication failed/cancelled', tag: 'SecurityService');
      }
      return authenticated;
    } catch (e) {
      AppLogger.error('Error during security authentication', error: e, tag: 'SecurityService');
      return false;
    }
  }
}
