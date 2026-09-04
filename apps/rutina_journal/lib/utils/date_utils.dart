import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static String toDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime fromDateKey(String key) {
    return DateTime.parse(key);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static List<DateTime> getPastDays(int count) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(
      count,
      (i) => today.subtract(Duration(days: count - 1 - i)),
    );
  }

  static List<DateTime> getWeekDaysAround(DateTime center, {int daysBefore = 3, int daysAfter = 3}) {
    final cleanCenter = DateTime(center.year, center.month, center.day);
    final total = daysBefore + daysAfter + 1;
    return List.generate(
      total,
      (i) => cleanCenter.subtract(Duration(days: daysBefore - i)),
    );
  }
}
