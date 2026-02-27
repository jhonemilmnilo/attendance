import 'package:flutter/material.dart';
import '../models/attendance_log_model.dart';
import '../models/department_schedule_model.dart';

class SalaryCalculator {
  final double hourlyRate;
  final DepartmentScheduleModel schedule;

  SalaryCalculator({required this.hourlyRate, required this.schedule});

  Map<String, dynamic> calculateDaily(
    AttendanceLogModel log,
    List<Map<String, dynamic>> approvedOT,
  ) {
    if (log.timeIn == null || log.timeOut == null) {
      return {
        'workMinutes': 0,
        'lateMinutes': 0,
        'undertimeMinutes': 0,
        'otMinutes': 0,
        'netPay': 0.0,
      };
    }

    final timeIn = _parseTime(log.timeIn!);
    final timeOut = _parseTime(log.timeOut!);
    final workStart = schedule.workStart;
    final workEnd = schedule.workEnd;

    // 1. Convert to minutes from midnight
    final timeInMins = timeIn.hour * 60 + timeIn.minute;
    final timeOutMins = timeOut.hour * 60 + timeOut.minute;
    final workStartMins = workStart.hour * 60 + workStart.minute;
    final workEndMins = workEnd.hour * 60 + workEnd.minute;

    // 2. Late Minutes (5-min grace period)
    int lateMinutes = 0;
    if (timeInMins > workStartMins) {
      final diff = timeInMins - workStartMins;
      if (diff > 5) {
        lateMinutes = diff;
      }
    }

    // 3. Undertime Minutes
    int undertimeMinutes = 0;
    if (timeOutMins < workEndMins) {
      undertimeMinutes = workEndMins - timeOutMins;
    }

    // 4. Overtime (Approved and > 90 mins)
    int otMinutes = 0;
    final actualOT = timeOutMins > workEndMins ? timeOutMins - workEndMins : 0;

    // Check if this specific date has an approved OT request
    bool isOTApproved = approvedOT.any(
      (ot) => ot['request_date'] == log.logDate,
    );

    if (actualOT > 90 && isOTApproved) {
      otMinutes = actualOT;
    }

    // 5. Scheduled Work Minutes (Base for deductions)
    // Formula: (Shift Duration) - 60 mins break
    int scheduledShiftDuration = workEndMins - workStartMins;
    int scheduledWorkMinutes = scheduledShiftDuration - 60;
    if (scheduledWorkMinutes < 0) scheduledWorkMinutes = 0;

    // 6. Net Work Minutes
    // Start with scheduled minutes, subtract penalties, add approved OT
    int netWorkMinutes =
        scheduledWorkMinutes - lateMinutes - undertimeMinutes + otMinutes;
    if (netWorkMinutes < 0) netWorkMinutes = 0;

    double netPay = (netWorkMinutes / 60.0) * hourlyRate;

    return {
      'workMinutes': scheduledWorkMinutes,
      'lateMinutes': lateMinutes,
      'undertimeMinutes': undertimeMinutes,
      'otMinutes': otMinutes,
      'netPay': netPay,
    };
  }

  TimeOfDay _parseTime(String iso) {
    final rawValue = iso.replaceAll(RegExp(r'[Z+].*'), '');
    final dt = DateTime.parse(rawValue);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }
}
