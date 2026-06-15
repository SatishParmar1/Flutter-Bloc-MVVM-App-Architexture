import 'package:flutter/services.dart';

class InputFormatters {
  InputFormatters._();

  static TextInputFormatter get creditCardFormatter {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text.replaceAll(RegExp(r'\s+\b|\b\s+'), '');
      if (newValue.text.length < oldValue.text.length) {
        return newValue;
      }
      
      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        final nonZeroIndex = i + 1;
        if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
          buffer.write(' ');
        }
      }
      
      final string = buffer.toString();
      return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length),
      );
    });
  }

  static TextInputFormatter get digitsOnly {
    return FilteringTextInputFormatter.digitsOnly;
  }

  static TextInputFormatter get usPhoneFormatter {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text.replaceAll(RegExp(r'\D'), '');
      if (newValue.text.length < oldValue.text.length) {
        return newValue;
      }
      
      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        if (i == 0) buffer.write('(');
        if (i == 3) buffer.write(') ');
        if (i == 6) buffer.write('-');
        buffer.write(text[i]);
      }
      
      final string = buffer.toString();
      return newValue.copyWith(
        text: string,
        selection: TextSelection.collapsed(offset: string.length),
      );
    });
  }
}
