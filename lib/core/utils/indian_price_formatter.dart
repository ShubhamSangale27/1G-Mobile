import 'package:intl/intl.dart';

/// Mirrors Angular `IndianPricePipe`.
class IndianPriceFormatter {
  static String format(num price) {
    if (price >= 10000000) {
      final cr = price / 10000000;
      final s = cr.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      return '₹$s Cr';
    }
    if (price >= 100000) {
      final l = price / 100000;
      return '₹${l.round()} L';
    }
    return '₹${NumberFormat.decimalPattern('en-IN').format(price)}';
  }

  static String formatLabel(num rupees) {
    if (rupees >= 10000000) {
      return '₹${(rupees / 10000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Cr';
    }
    if (rupees >= 100000) return '₹${(rupees / 100000).round()} L';
    return '₹${(rupees / 1000).round()}K';
  }
}
