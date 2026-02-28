import 'package:flutter/material.dart';

enum OvertimeStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static OvertimeStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return OvertimeStatus.approved;
      case 'rejected':
        return OvertimeStatus.rejected;
      case 'cancelled':
        return OvertimeStatus.cancelled;
      case 'pending':
      default:
        return OvertimeStatus.pending;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case OvertimeStatus.pending:
        return 'Pending';
      case OvertimeStatus.approved:
        return 'Approved';
      case OvertimeStatus.rejected:
        return 'Rejected';
      case OvertimeStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OvertimeStatus.pending:
        return Colors.orange;
      case OvertimeStatus.approved:
        return Colors.green;
      case OvertimeStatus.rejected:
        return Colors.red;
      case OvertimeStatus.cancelled:
        return Colors.grey;
    }
  }
}

class OvertimeRequestModel {
  final int? overtimeId;
  final int userId;
  final int? departmentId;
  final int? logId;
  final DateTime requestDate;
  final String schedTimeout;
  final String otFrom;
  final String otTo;
  final int durationMinutes;
  final String purpose;
  final String? remarks;
  final OvertimeStatus status;
  final int? approverId;
  final DateTime? approvedAt;
  final DateTime? filedAt;

  OvertimeRequestModel({
    this.overtimeId,
    required this.userId,
    this.departmentId,
    this.logId,
    required this.requestDate,
    required this.schedTimeout,
    required this.otFrom,
    required this.otTo,
    required this.durationMinutes,
    required this.purpose,
    this.remarks,
    this.status = OvertimeStatus.pending,
    this.approverId,
    this.approvedAt,
    this.filedAt,
  });

  factory OvertimeRequestModel.fromJson(Map<String, dynamic> json) {
    return OvertimeRequestModel(
      overtimeId: json['overtime_id'] != null
          ? int.parse(json['overtime_id'].toString())
          : null,
      userId: int.parse(json['user_id'].toString()),
      departmentId: json['department_id'] != null
          ? int.parse(json['department_id'].toString())
          : null,
      logId: json['log_id'] != null
          ? int.parse(json['log_id'].toString())
          : null,
      requestDate: DateTime.parse(json['request_date']),
      schedTimeout: json['sched_timeout'],
      otFrom: json['ot_from'],
      otTo: json['ot_to'],
      durationMinutes: int.parse(json['duration_minutes'].toString()),
      purpose: json['purpose'],
      remarks: json['remarks'],
      status: OvertimeStatus.fromString(json['status']),
      approverId: json['approver_id'] != null
          ? int.parse(json['approver_id'].toString())
          : null,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      filedAt: json['filed_at'] != null
          ? DateTime.parse(json['filed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overtime_id': overtimeId,
      'user_id': userId,
      'department_id': departmentId,
      'log_id': logId,
      'request_date': requestDate.toIso8601String().split('T')[0],
      'sched_timeout': schedTimeout,
      'ot_from': otFrom,
      'ot_to': otTo,
      'duration_minutes': durationMinutes,
      'purpose': purpose,
      'remarks': remarks,
      'status': status.value,
      'approver_id': approverId,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }
}
