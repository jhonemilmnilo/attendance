import 'package:flutter/material.dart' show TimeOfDay, DayPeriod;
import 'package:intl/intl.dart';

enum UndertimeStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static UndertimeStatus fromString(String status) {
    return UndertimeStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => UndertimeStatus.pending,
    );
  }
}

class UndertimeRequestModel {
  final int? undertimeId;
  final int userId;
  final int? departmentId;
  final int? logId;
  final DateTime requestDate;
  final String schedTimeout; // TIME format (HH:mm:ss)
  final String actualTimeout; // TIME format (HH:mm:ss)
  final int durationMinutes;
  final String reason;
  final String? remarks;
  final UndertimeStatus status;
  final int? approverId;
  final DateTime? approvedAt;
  final DateTime? filedAt;
  final DateTime? updatedAt;

  const UndertimeRequestModel({
    this.undertimeId,
    required this.userId,
    this.departmentId,
    this.logId,
    required this.requestDate,
    required this.schedTimeout,
    required this.actualTimeout,
    required this.durationMinutes,
    required this.reason,
    this.remarks,
    this.status = UndertimeStatus.pending,
    this.approverId,
    this.approvedAt,
    this.filedAt,
    this.updatedAt,
  });

  factory UndertimeRequestModel.fromJson(Map<String, dynamic> json) {
    return UndertimeRequestModel(
      undertimeId: json['undertime_id'],
      userId: json['user_id'],
      departmentId: json['department_id'],
      logId: json['log_id'],
      requestDate: DateTime.parse(json['request_date']),
      schedTimeout: json['sched_timeout'],
      actualTimeout: json['actual_timeout'],
      durationMinutes: json['duration_minutes'] ?? 0,
      reason: json['reason'] ?? '',
      remarks: json['remarks'],
      status: UndertimeStatus.fromString(json['status'] ?? 'pending'),
      approverId: json['approver_id'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      filedAt: json['filed_at'] != null
          ? DateTime.parse(json['filed_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': userId,
      'department_id': departmentId,
      'log_id': logId,
      'request_date': DateFormat('yyyy-MM-dd').format(requestDate),
      'sched_timeout': schedTimeout,
      'actual_timeout': actualTimeout,
      'duration_minutes': durationMinutes,
      'reason': reason,
      'remarks': remarks,
      'status': status.name,
    };

    if (undertimeId != null) data['undertime_id'] = undertimeId;
    if (approverId != null) data['approver_id'] = approverId;
    if (approvedAt != null) data['approved_at'] = approvedAt!.toIso8601String();

    return data;
  }

  String get formattedRequestDate =>
      DateFormat('MMM dd, yyyy').format(requestDate);

  String get formattedSchedTimeout {
    try {
      final parts = schedTimeout.split(':');
      final time = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      return _formatTimeOfDay(time);
    } catch (_) {
      return schedTimeout;
    }
  }

  String get formattedActualTimeout {
    try {
      final parts = actualTimeout.split(':');
      final time = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      return _formatTimeOfDay(time);
    } catch (_) {
      return actualTimeout;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period";
  }
}
