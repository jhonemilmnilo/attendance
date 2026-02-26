import 'package:intl/intl.dart';

/// AttendanceLog model representing an attendance record
class AttendanceLogModel {
  final int logId;
  final int userId;
  final int departmentId;
  final String logDate;
  final String? timeIn;
  final String? lunchStart;
  final String? lunchEnd;
  final String? breakStart;
  final String? breakEnd;
  final String? timeOut;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  AttendanceLogModel({
    required this.logId,
    required this.userId,
    required this.departmentId,
    required this.logDate,
    this.timeIn,
    this.lunchStart,
    this.lunchEnd,
    this.breakStart,
    this.breakEnd,
    this.timeOut,
    this.status = 'On Time',
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for creating AttendanceLogModel from JSON data
  factory AttendanceLogModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLogModel(
      logId: json['log_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      departmentId: json['department_id'] ?? 0,
      logDate: json['log_date'] ?? '',
      timeIn: json['time_in'],
      lunchStart: json['lunch_start'],
      lunchEnd: json['lunch_end'],
      breakStart: json['break_start'],
      breakEnd: json['break_end'],
      timeOut: json['time_out'],
      status: json['status'] ?? 'On Time',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  /// Convert AttendanceLogModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'user_id': userId,
      'department_id': departmentId,
      'log_date': logDate,
      'time_in': timeIn,
      'lunch_start': lunchStart,
      'lunch_end': lunchEnd,
      'break_start': breakStart,
      'break_end': breakEnd,
      'time_out': timeOut,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Get parsed DateTime for log date
  DateTime get parsedDate => DateTime.parse(logDate);

  /// Get formatted date string
  String get formattedDate {
    try {
      return DateFormat('MMMM d, yyyy').format(parsedDate);
    } catch (_) {
      return logDate;
    }
  }

  /// Get formatted short date string
  String get shortDate {
    try {
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (_) {
      return logDate;
    }
  }

  /// Helper to parse time as local wall-clock, ignoring any server-provided TZ
  DateTime _parseWallClock(String? iso) {
    if (iso == null || iso.isEmpty) return DateTime.now();
    try {
      // Strip 'Z' or '+HH:mm' to treat strings as local "wall-clock" digits
      final rawValue = iso.replaceAll(RegExp(r'[Z+].*'), '');
      return DateTime.parse(rawValue);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Get formatted time from ISO string
  String? get formattedTimeIn {
    if (timeIn == null) return null;
    return DateFormat('h:mm a').format(_parseWallClock(timeIn));
  }

  /// Get formatted time out from ISO string
  String? get formattedTimeOut {
    if (timeOut == null) return null;
    return DateFormat('h:mm a').format(_parseWallClock(timeOut));
  }

  /// Get formatted lunch start
  String? get formattedLunchStart {
    if (lunchStart == null) return null;
    return DateFormat('h:mm a').format(_parseWallClock(lunchStart));
  }

  /// Get formatted lunch end
  String? get formattedLunchEnd {
    if (lunchEnd == null) return null;
    return DateFormat('h:mm a').format(_parseWallClock(lunchEnd));
  }

  /// Get formatted break start
  String? get formattedBreakStart {
    if (breakStart == null) return null;
    return DateFormat('h:mm a').format(_parseWallClock(breakStart));
  }

  /// Get formatted break end
  String? get formattedBreakEnd {
    if (breakEnd == null) return null;
    return DateFormat('h:mm a').format(_parseWallClock(breakEnd));
  }

  /// Get formatted created at
  String? get formattedCreatedAt {
    if (createdAt == null) return null;
    return DateFormat('MMM dd, yyyy h:mm a').format(_parseWallClock(createdAt));
  }

  /// Get formatted updated at
  String? get formattedUpdatedAt {
    if (updatedAt == null) return null;
    return DateFormat('MMM dd, yyyy h:mm a').format(_parseWallClock(updatedAt));
  }

  /// Get current status based on time entries
  AttendanceStatus get currentStatus {
    if (timeOut != null) return AttendanceStatus.clockedOut;
    if (lunchStart != null && lunchEnd == null) return AttendanceStatus.onLunch;
    if (breakStart != null && breakEnd == null) return AttendanceStatus.onBreak;
    if (timeIn != null) return AttendanceStatus.working;
    return AttendanceStatus.notClockedIn;
  }
}

/// Enum for attendance status
enum AttendanceStatus {
  notClockedIn,
  working,
  onLunch,
  onBreak,
  clockedOut;

  String get displayText {
    switch (this) {
      case AttendanceStatus.notClockedIn:
        return 'Not Clocked In';
      case AttendanceStatus.working:
        return 'Working';
      case AttendanceStatus.onLunch:
        return 'On Lunch';
      case AttendanceStatus.onBreak:
        return 'On Break';
      case AttendanceStatus.clockedOut:
        return 'Clocked Out';
    }
  }
}
