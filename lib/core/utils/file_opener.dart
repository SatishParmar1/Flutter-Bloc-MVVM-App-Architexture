import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'logger.dart';

class FileOpener {
  FileOpener._();

  static Future<bool> openLocalFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.error('File does not exist: $filePath', tag: 'FileOpener');
        return false;
      }

      final result = await OpenFilex.open(filePath);
      if (result.type == ResultType.done) {
        AppLogger.success('Successfully opened local file: $filePath', tag: 'FileOpener');
        return true;
      } else {
        AppLogger.warning('Could not open file natively. Message: ${result.message}', tag: 'FileOpener');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('Error opening local file: $filePath', error: e, stackTrace: stack, tag: 'FileOpener');
      return false;
    }
  }

  static Future<bool> openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (success) {
          AppLogger.success('Successfully launched URL: $urlString', tag: 'FileOpener');
          return true;
        }
      }
      AppLogger.warning('Cannot launch URL: $urlString', tag: 'FileOpener');
      return false;
    } catch (e, stack) {
      AppLogger.error('Error launching URL: $urlString', error: e, stackTrace: stack, tag: 'FileOpener');
      return false;
    }
  }

  static Future<bool> openEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final query = <String, String>{
      if (subject != null) 'subject': subject,
      if (body != null) 'body': body,
    };
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: query.isEmpty ? null : query,
    );
    return openUrl(uri.toString());
  }

  static Future<bool> makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    return openUrl('tel:$cleanNumber');
  }

  static Future<bool> sendSms(String phoneNumber, {String? body}) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanNumber,
      queryParameters: body != null ? {'body': body} : null,
    );
    return openUrl(uri.toString());
  }
}
