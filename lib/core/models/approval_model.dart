import 'package:intl/intl.dart';

/// Approval model representing an attendance approval record
class ApprovalModel {
  final int approvalId;
  final int employeeId;
  final String dateSchedule;
  final int workMinutes;
  final int lateMinutes;
  final int undertimeMinutes;
  final int overtimeMinutes;
  final String status;
  final String? remarks;

  ApprovalModel({
    required this.approvalId,
    required this.employeeId,
    required this.dateSchedule,
    required this.workMinutes,
    required this.lateMinutes,
    required this.undertimeMinutes,
    required this.overtimeMinutes,
    required this.status,
    this.remarks,
  });

  /// Factory constructor for creating ApprovalModel from JSON data
  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      approvalId: json['approval_id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      dateSchedule: json['date_schedule'] ?? '',
      workMinutes: json['work_minutes'] ?? 0,
      lateMinutes: json['late_minutes'] ?? 0,
      undertimeMinutes: json['undertime_minutes'] ?? 0,
      overtimeMinutes: json['overtime_minutes'] ?? 0,
      status: json['status'] ?? '',
      remarks: json['remarks'],
    );
  }

  /// Convert ApprovalModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'approval_id': approvalId,
      'employee_id': employeeId,
      'date_schedule': dateSchedule,
      'work_minutes': workMinutes,
      'late_minutes': lateMinutes,
      'undertime_minutes': undertimeMinutes,
      'overtime_minutes': overtimeMinutes,
      'status': status,
      'remarks': remarks,
    };
  }

  /// Get parsed DateTime
  DateTime get parsedDate => DateTime.parse(dateSchedule);

  /// Get formatted date string
  String get formattedDate {
    try {
      return DateFormat('MMMM d, yyyy').format(parsedDate);
    } catch (_) {
      return dateSchedule;
    }
  }

  /// Get formatted short date string
  String get shortDate {
    try {
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (_) {
      return dateSchedule;
    }
  }

  /// Get formatted work hours (minutes to hours:minutes)
  String get formattedWorkHours {
    final hours = workMinutes ~/ 60;
    final minutes = workMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Get formatted overtime (minutes to hours:minutes)
  String get formattedOvertime {
    final hours = overtimeMinutes ~/ 60;
    final minutes = overtimeMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}

/// Enum for approval status
enum ApprovalStatus {
  pending,
  approved,
  rejected;

  static ApprovalStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      default:
        return ApprovalStatus.pending;
    }
  }

  String get displayText {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
    }
  }
}
