import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeviceUtils {
  DeviceUtils._();

  static void hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  static Future<void> setPreferredOrientations(List<DeviceOrientation> orientations) {
    return SystemChrome.setPreferredOrientations(orientations);
  }

  static void setStatusBarColor({
    required Color color,
    Brightness? iconBrightness,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: color,
        statusBarIconBrightness: iconBrightness ?? Brightness.light,
        statusBarBrightness: iconBrightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );
  }

  static Future<void> copyToClipboard(String text) {
    return Clipboard.setData(ClipboardData(text: text));
  }
}
