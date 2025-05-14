import 'package:intl/intl.dart';

class DateTimeFmt {
  static String date(DateTime dateTime) {
    return DateFormat('dd MMM yyyy', 'es_ES').format(dateTime);
  }

  static String time(DateTime dateTime) {
    return DateFormat('HH:mm', 'es_ES').format(dateTime);
  }

  static String timeRange(DateTime start, DateTime end) {
    return '${DateFormat('hh:mm a', 'es_ES').format(start)} - ${DateFormat('hh:mm a', 'es_ES').format(end)}';
  }

  static String full(DateTime dateTime) {
    return DateFormat('dd MMM yyyy HH:mm', 'es_ES').format(dateTime);
  }

  static String getTimeUntil(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Ya pasó';
    }

    if (difference.inDays > 0) {
      return 'En ${difference.inDays} día(s)';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} hora(s)';
    } else if (difference.inMinutes > 0) {
      return 'En ${difference.inMinutes} minuto(s)';
    } else {
      return 'En unos segundos';
    }
  }
}
