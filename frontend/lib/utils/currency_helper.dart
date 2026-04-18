class CurrencyHelper {
  static String getSymbol(String? currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'CAD':
        return 'CA\$';
      case 'GBP':
        return '£';
      case 'BRL':
      default:
        return 'R\$';
    }
  }

  static String format(double value, String? currencyCode) {
    final symbol = getSymbol(currencyCode);
    return '$symbol ${value.toStringAsFixed(2)}';
  }
}
