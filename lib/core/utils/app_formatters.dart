import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  static final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final date = DateFormat('dd/MM/yyyy');
  static final dateTime = DateFormat('dd/MM/yyyy HH:mm');
  static final time = DateFormat('HH:mm');
}

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.simpleCurrency(locale: 'pt_BR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    final value = int.parse(digitsOnly);
    final double realValue = value / 100.0;
    String formattedText = _formatter.format(realValue);

    String finalValue = formattedText
        .replaceAll(_formatter.currencySymbol, '')
        .trim();

    return TextEditingValue(
      text: finalValue,
      selection: TextSelection.collapsed(offset: finalValue.length),
    );
  }
}

class TimeRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    String newText = '';

    if (text.isNotEmpty) {
      newText += text.substring(0, text.length > 2 ? 2 : text.length);
      if (text.length > 2) {
        newText += ':';
        newText += text.substring(2, text.length > 4 ? 4 : text.length);
      }
    }

    if (text.length >= 5) {
      newText += ' - ';
      String secondTimeDigits = text.substring(4);

      if (secondTimeDigits.isNotEmpty) {
        newText += secondTimeDigits.substring(
          0,
          secondTimeDigits.length > 2 ? 2 : secondTimeDigits.length,
        );
      }
      if (secondTimeDigits.length > 2) {
        newText += ':';
        newText += secondTimeDigits.substring(
          2,
          secondTimeDigits.length > 4 ? 4 : secondTimeDigits.length,
        );
      }
    }

    if (newText.length > 13) {
      newText = newText.substring(0, 13);
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}