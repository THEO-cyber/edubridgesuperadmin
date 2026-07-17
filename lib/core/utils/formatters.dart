import 'package:intl/intl.dart';

abstract final class Formatters {
  // Platform currency is XAF (Central African CFA franc) — zero-decimal.
  static String currency(dynamic value, {String symbol = 'FCFA'}) {
    final n = double.tryParse(value.toString()) ?? 0;
    return '${NumberFormat('#,##0').format(n)} $symbol';
  }

  static String number(dynamic value) {
    final n = int.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,##0').format(n);
  }

  static String compact(dynamic value) {
    final n = num.tryParse(value.toString()) ?? 0;
    return NumberFormat.compact().format(n);
  }

  static String date(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  static String dateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy · h:mm a').format(dt);
  }

  static String timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return date(dt);
  }

  static String percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
