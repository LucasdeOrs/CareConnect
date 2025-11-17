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
