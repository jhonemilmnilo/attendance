import 'package:flutter/material.dart';

class DepartmentScheduleModel {
  final int scheduleId;
  final int departmentId;
  final int workingDays;
  final TimeOfDay workStart;
  final TimeOfDay workEnd;
  final TimeOfDay lunchStart;
  final TimeOfDay lunchEnd;
  final TimeOfDay breakStart;
  final TimeOfDay breakEnd;
  final String? workdaysNote;

  DepartmentScheduleModel({
    required this.scheduleId,
    required this.departmentId,
    required this.workingDays,
    required this.workStart,
    required this.workEnd,
    required this.lunchStart,
    required this.lunchEnd,
    required this.breakStart,
    required this.breakEnd,
    this.workdaysNote,
  });

  factory DepartmentScheduleModel.fromJson(Map<String, dynamic> json) {
    TimeOfDay parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) {
        return const TimeOfDay(hour: 0, minute: 0);
      }
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return DepartmentScheduleModel(
      scheduleId: json['schedule_id'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      workingDays: json['working_days'] ?? 0,
      workStart: parseTime(json['work_start']),
      workEnd: parseTime(json['work_end']),
      lunchStart: parseTime(json['lunch_start']),
      lunchEnd: parseTime(json['lunch_end']),
      breakStart: parseTime(json['break_start']),
      breakEnd: parseTime(json['break_end']),
      workdaysNote: json['workdays_note'],
    );
  }
}
