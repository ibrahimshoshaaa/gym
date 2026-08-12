import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String toDisplayDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String toDisplayDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy - hh:mm a').format(date);
  }

  static String toTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// عدد الأيام المتبقية على انتهاء الاشتراك (بيرجع بالسالب لو خلص)
  static int daysRemaining(DateTime endDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(today).inDays;
  }

  static bool isExpiringSoon(DateTime endDate, {int thresholdDays = 3}) {
    final remaining = daysRemaining(endDate);
    return remaining >= 0 && remaining <= thresholdDays;
  }

  static bool isExpired(DateTime endDate) {
    return daysRemaining(endDate) < 0;
  }
}
