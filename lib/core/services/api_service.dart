import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/approval_model.dart';
import '../models/attendance_log_model.dart';
import '../models/user_model.dart';

/// API Service for handling all backend communications
class ApiService {
  static const String baseUrl = 'http://goatedcodoer:8090';

  /// Formats a DateTime to ISO 8601 string WITH timezone offset.
  /// This prevents the server from misinterpreting local time as UTC.
  /// e.g. "2026-02-17T12:00:00.000+08:00" instead of "2026-02-17T12:00:00.000"
  String _formatWithOffset(DateTime dt) {
    // Return raw ISO string without TZ indicator to treat as local "wall-clock" time
    return dt.toIso8601String();
  }

  // ==================== Authentication ====================

  /// Authenticate user with email and password
  /// Returns UserModel if successful, null otherwise
  Future<UserModel?> login(String email, String password) async {
    try {
      final url = Uri.parse(
        '$baseUrl/items/user?filter[user_email][_eq]=$email&limit=1',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          final userData = data['data'][0];
          if (userData['user_password'] == password) {
            return UserModel.fromJson(userData);
          }
        }
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  // ==================== Attendance Log ====================

  /// Get today's attendance log for a specific user
  Future<AttendanceLogModel?> getTodayLog(int userId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final url = Uri.parse(
      '$baseUrl/items/attendance_log?filter[user_id][_eq]=$userId&filter[log_date][_eq]=$today&limit=1',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          return AttendanceLogModel.fromJson(data['data'][0]);
        }
      }
    } catch (e) {
      print("Get Log Error: $e");
    }
    return null;
  }

  /// Create a new attendance log (Time In)
  Future<bool> createLog({
    required int userId,
    required int departmentId,
    required DateTime date,
    DateTime? timeIn,
    DateTime? lunchStart,
    DateTime? lunchEnd,
    DateTime? breakStart,
    DateTime? breakEnd,
    DateTime? timeOut,
  }) async {
    final url = Uri.parse('$baseUrl/items/attendance_log');
    final logDate = DateFormat('yyyy-MM-dd').format(date);

    final body = {
      "user_id": userId,
      "department_id": departmentId,
      "log_date": logDate,
      "status": "On Time",
    };

    if (timeIn != null) body['time_in'] = _formatWithOffset(timeIn);
    if (lunchStart != null) body['lunch_start'] = _formatWithOffset(lunchStart);
    if (lunchEnd != null) body['lunch_end'] = _formatWithOffset(lunchEnd);
    if (breakStart != null) body['break_start'] = _formatWithOffset(breakStart);
    if (breakEnd != null) body['break_end'] = _formatWithOffset(breakEnd);
    if (timeOut != null) body['time_out'] = _formatWithOffset(timeOut);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Create Log Error: $e");
      return false;
    }
  }

  /// Update an existing log (Lunch, Break, Time Out)
  Future<bool> updateLog({
    required int logId,
    DateTime? timeIn,
    DateTime? lunchStart,
    DateTime? lunchEnd,
    DateTime? breakStart,
    DateTime? breakEnd,
    DateTime? timeOut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final url = Uri.parse('$baseUrl/items/attendance_log/$logId');

    final Map<String, dynamic> body = {};
    if (timeIn != null) body['time_in'] = _formatWithOffset(timeIn);
    if (lunchStart != null) body['lunch_start'] = _formatWithOffset(lunchStart);
    if (lunchEnd != null) body['lunch_end'] = _formatWithOffset(lunchEnd);
    if (breakStart != null) body['break_start'] = _formatWithOffset(breakStart);
    if (breakEnd != null) body['break_end'] = _formatWithOffset(breakEnd);
    if (timeOut != null) body['time_out'] = _formatWithOffset(timeOut);
    if (createdAt != null) body['created_at'] = _formatWithOffset(createdAt);
    if (updatedAt != null) body['updated_at'] = _formatWithOffset(updatedAt);

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Log Error: $e");
      return false;
    }
  }

  /// Get attendance history logs with pagination
  Future<List<AttendanceLogModel>> getHistory(
    int userId, {
    int page = 1,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '$baseUrl/items/attendance_log?filter[user_id][_eq]=$userId&sort=-log_date&limit=$limit&page=$page',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((e) => AttendanceLogModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Get History Error: $e");
    }
    return [];
  }

  // ==================== Approvals ====================

  /// Get pending approvals for a user
  Future<List<ApprovalModel>> getApprovals(int userId) async {
    final url = Uri.parse(
      'http://goatedcodoer:8090/items/attendance_approval?filter[status][_eq]=approved&filter[employee_id][_eq]=$userId&limit=-1&sort=-date_schedule',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((e) => ApprovalModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Get Approvals Error: $e");
    }
    return [];
  }

  /// Update an approval record
  Future<bool> updateApproval(int approvalId, Map<String, dynamic> data) async {
    final url = Uri.parse(
      'http://goatedcodoer:8090/items/attendance_approval/$approvalId',
    );
    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Approval Error: $e");
      return false;
    }
  }
}
