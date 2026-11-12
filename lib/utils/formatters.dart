import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yy');

  static String format(
    double amount, {
    String currency = 'GTQ',
    bool showSign = false,
  }) {
    final symbol = _symbolFor(currency);
    final absFormatted = _formatter.format(amount.abs());
    if (amount < 0) {
      return '-$symbol$absFormatted';
    }
    if (showSign && amount > 0) {
      return '+$symbol$absFormatted';
    }
    return '$symbol$absFormatted';
  }

  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  static String _symbolFor(String currency) {
    switch (currency.toUpperCase()) {
      case 'GTQ':
        return 'Q';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'MXN':
        return 'MX\$';
      default:
        return 'Q';
    }
  }
}
