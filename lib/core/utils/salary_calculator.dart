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

    final ti = DateTime.parse(log.timeIn!.replaceAll(RegExp(r'[Z+].*'), ''));
    final to = DateTime.parse(log.timeOut!.replaceAll(RegExp(r'[Z+].*'), ''));

    // Construct baseline schedule times for the log date
    final logDate = DateTime.parse(log.logDate);
    final workStart = DateTime(
      logDate.year,
      logDate.month,
      logDate.day,
      schedule.workStart.hour,
      schedule.workStart.minute,
    );

    var workEnd = DateTime(
      logDate.year,
      logDate.month,
      logDate.day,
      schedule.workEnd.hour,
      schedule.workEnd.minute,
    );

    // If workEnd is before workStart, it's an overnight shift schedule (unlikely for this app structure but good to handle)
    // However, the user specifically mentioned TI 8:00 AM, TO 1:00 AM (next day).
    // In this case, workEnd is 5:00 PM same day.

    // 1. Late Minutes (5-min grace period)
    int lateMinutes = 0;
    if (ti.isAfter(workStart)) {
      final diff = ti.difference(workStart).inMinutes;
      if (diff > 5) {
        lateMinutes = diff;
      }
    }

    // 2. Overtime Calculation (Approved and > 90 mins)
    int otMinutes = 0;
    if (to.isAfter(workEnd)) {
      final actualOT = to.difference(workEnd).inMinutes;

      // Check if this specific date has an approved OT request
      bool isOTApproved = approvedOT.any(
        (ot) => ot['request_date'] == log.logDate,
      );

      // User rule: only count if approved and > 90 mins
      if (actualOT > 90 && isOTApproved) {
        otMinutes = actualOT;
      }
    }

    // 3. Undertime Calculation (Only if TO is before workEnd)
    int undertimeMinutes = 0;
    if (to.isBefore(workEnd)) {
      undertimeMinutes = workEnd.difference(to).inMinutes;
    }

    // 4. Scheduled shift duration (Base 8 hours usually)
    // Formula: (Shift Duration) - 60 mins break
    int scheduledShiftDuration = workEnd.difference(workStart).inMinutes;
    int scheduledWorkMinutes = scheduledShiftDuration - 60;
    if (scheduledWorkMinutes < 0) scheduledWorkMinutes = 0;

    // 5. Net Work Minutes
    // If the employee stayed very long (like 1 AM), but OT is NOT approved,
    // they should get their standard 8 hours (minus lates/undertime).
    // If OT IS approved, they get standard + OT.
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
}
