import 'package:intl/intl.dart';

class PriceFormatter {
  PriceFormatter._();

  static final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);

  static String brl(double value) => _brl.format(value);
}
