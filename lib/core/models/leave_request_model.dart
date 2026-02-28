import 'package:flutter/material.dart';

enum LeaveType {
  vacation,
  sick,
  emergency,
  special,
  unpaid,
  others;

  static LeaveType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'sick':
        return LeaveType.sick;
      case 'emergency':
        return LeaveType.emergency;
      case 'special':
        return LeaveType.special;
      case 'unpaid':
        return LeaveType.unpaid;
      case 'others':
        return LeaveType.others;
      case 'vacation':
      default:
        return LeaveType.vacation;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case LeaveType.vacation:
        return 'Vacation';
      case LeaveType.sick:
        return 'Sick';
      case LeaveType.emergency:
        return 'Emergency';
      case LeaveType.special:
        return 'Special';
      case LeaveType.unpaid:
        return 'Unpaid';
      case LeaveType.others:
        return 'Others';
    }
  }
}

enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static LeaveStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'cancelled':
        return LeaveStatus.cancelled;
      case 'pending':
      default:
        return LeaveStatus.pending;
    }
  }

  String get value => name;

  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.cancelled:
        return Colors.grey;
    }
  }
}

class LeaveRequestModel {
  final int? leaveId;
  final int userId;
  final int? departmentId;
  final LeaveType leaveType;
  final DateTime leaveStart;
  final DateTime leaveEnd;
  final double totalDays;
  final String? reason;
  final String? remarks;
  final LeaveStatus status;
  final int? approverId;
  final DateTime? approvedAt;
  final DateTime? filedAt;

  LeaveRequestModel({
    this.leaveId,
    required this.userId,
    this.departmentId,
    required this.leaveType,
    required this.leaveStart,
    required this.leaveEnd,
    required this.totalDays,
    this.reason,
    this.remarks,
    this.status = LeaveStatus.pending,
    this.approverId,
    this.approvedAt,
    this.filedAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      leaveId: json['leave_id'] != null
          ? int.parse(json['leave_id'].toString())
          : null,
      userId: int.parse(json['user_id'].toString()),
      departmentId: json['department_id'] != null
          ? int.parse(json['department_id'].toString())
          : null,
      leaveType: LeaveType.fromString(json['leave_type']),
      leaveStart: DateTime.parse(json['leave_start']),
      leaveEnd: DateTime.parse(json['leave_end']),
      totalDays: double.parse(json['total_days'].toString()),
      reason: json['reason'],
      remarks: json['remarks'],
      status: LeaveStatus.fromString(json['status']),
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
      'leave_id': leaveId,
      'user_id': userId,
      'department_id': departmentId,
      'leave_type': leaveType.value,
      'leave_start': leaveStart.toIso8601String().split('T')[0],
      'leave_end': leaveEnd.toIso8601String().split('T')[0],
      'total_days': totalDays,
      'reason': reason,
      'remarks': remarks,
      'status': status.value,
      'approver_id': approverId,
      'approved_at': approvedAt?.toIso8601String(),
    };
  }

  String get formattedTotalDays {
    if (totalDays == totalDays.toInt()) {
      return "${totalDays.toInt()} ${totalDays.toInt() == 1 ? 'day' : 'days'}";
    }
    return "$totalDays ${totalDays == 1.0 ? 'day' : 'days'}";
  }
}
