import 'package:flutter/material.dart';

class TimeUtils {
  /// Converts 24-hour string like "14:30" or "09:00" to 12-hour AM/PM format "02:30 PM" / "09:00 AM"
  static String formatAmPm(String? time24) {
    if (time24 == null || time24.isEmpty) return '';
    try {
      final parts = time24.trim().split(':');
      if (parts.length < 2) return time24;
      int hour = int.parse(parts[0]);
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return time24;
    }
  }

  /// Formats TimeOfDay to AM/PM string like "10:30 AM"
  static String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
