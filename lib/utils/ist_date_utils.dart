import 'package:intl/intl.dart';

/// Central timezone and date utility for IST (Asia/Kolkata, UTC+05:30).
/// Guarantees that regardless of the device's system clock/timezone,
/// dates and times are formatted strictly according to Indian Standard Time.
class ISTDateUtils {
  ISTDateUtils._();

  static const Duration istOffset = Duration(hours: 5, minutes: 30);

  /// Converts any DateTime into an IST DateTime without depending on device local time.
  static DateTime toIST(DateTime dt) {
    final utc = dt.isUtc ? dt : dt.toUtc();
    return utc.add(istOffset);
  }

  /// Parses an ISO string or date string directly to IST.
  static DateTime? parseToIST(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      final parsed = DateTime.parse(dateStr.trim());
      return toIST(parsed);
    } catch (_) {
      return null;
    }
  }

  /// Formats date to 'dd MMM yyyy' in IST (e.g. '18 Oct 2026')
  static String formatISTDate(dynamic date, [String pattern = 'dd MMM yyyy']) {
    final ist = _resolveToIST(date);
    if (ist == null) return 'N/A';
    return DateFormat(pattern).format(ist);
  }

  /// Formats time to 12-hour 'hh:mm a' in IST (e.g. '08:30 PM')
  static String formatISTTime(dynamic date, [String pattern = 'hh:mm a']) {
    final ist = _resolveToIST(date);
    if (ist == null) return 'N/A';
    return DateFormat(pattern).format(ist);
  }

  /// Formats full datetime 'dd MMM yyyy, hh:mm a' in IST
  static String formatISTDateTime(dynamic date) {
    return formatISTDate(date, 'dd MMM yyyy, hh:mm a');
  }

  static DateTime? _resolveToIST(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return toIST(date);
    if (date is String) return parseToIST(date);
    return null;
  }
}
