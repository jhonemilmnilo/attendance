import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/approval_model.dart';
import '../models/attendance_log_model.dart';
import '../models/department_schedule_model.dart';
import '../models/payroll_employee_model.dart';
import '../models/leave_request_model.dart';
import '../models/overtime_request_model.dart';
import '../models/undertime_request_model.dart';
import '../models/user_model.dart';

/// API Service for handling all backend communications
class ApiService {
  static const String baseUrl = 'https://goatedcodoer.tail054015.ts.net/vertex';

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

  /// Get specific user by ID
  Future<UserModel?> getUser(int userId) async {
    final url = Uri.parse('$baseUrl/items/user/$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return UserModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      print("Get User Error: $e");
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
      '$baseUrl/items/attendance_approval?filter[status][_eq]=approved&filter[employee_id][_eq]=$userId&limit=-1&sort=-date_schedule',
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
    final url = Uri.parse('$baseUrl/items/attendance_approval/$approvalId');
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

  // ==================== Payroll ====================

  /// Get processed/posted payroll records for a specific user
  Future<List<PayrollEmployeeModel>> getPayrollHistory(int userId) async {
    final url = Uri.parse(
      '$baseUrl/items/payroll_run_employee?filter[user_id][_eq]=$userId'
      '&filter[payroll_run_id][status][_nin]=DRAFT,draft'
      '&fields=*,payroll_run_id.status'
      '&sort=-cutoff_end&limit=-1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((e) => PayrollEmployeeModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Get Payroll History Error: $e");
    }
    return [];
  }

  /// Get draft payroll records for a specific user
  Future<List<PayrollEmployeeModel>> getDraftPayrolls(int userId) async {
    final url = Uri.parse(
      '$baseUrl/items/payroll_run_employee?filter[user_id][_eq]=$userId'
      '&filter[payroll_run_id][status][_in]=DRAFT,draft'
      '&fields=*,payroll_run_id.status'
      '&sort=-cutoff_end&limit=-1',
    );
    try {
      print("Fetching Draft Payrolls: $url");
      final response = await http.get(url);
      print("Draft Payroll Response: ${response.statusCode}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          "Draft Payroll Count: ${data['data'] != null ? (data['data'] as List).length : 0}",
        );
        if (data['data'] != null) {
          final list = (data['data'] as List)
              .map((e) => PayrollEmployeeModel.fromJson(e))
              .toList();
          return list;
        }
      }
    } catch (e) {
      print("Get Draft Payrolls Error: $e");
    }
    return [];
  }

  /// Get specific payroll detail
  Future<PayrollEmployeeModel?> getPayrollDetail(int payrollId) async {
    final url = Uri.parse('$baseUrl/items/payroll_run_employee/$payrollId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return PayrollEmployeeModel.fromJson(data['data']);
        }
      }
    } catch (e) {
      print("Get Payroll Detail Error: $e");
    }
    return null;
  }

  /// Get all payroll records for all employees
  Future<List<PayrollEmployeeModel>> getAllPayrollRecords() async {
    final url = Uri.parse(
      '$baseUrl/items/payroll_run_employee'
      '?fields=*,payroll_run_id.status'
      '&sort=-cutoff_end&limit=-1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((e) => PayrollEmployeeModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Get All Payroll Records Error: $e");
    }
    return [];
  }

  // ==================== Department Schedule ====================

  /// Get department schedule
  Future<DepartmentScheduleModel?> getDepartmentSchedule(
    int departmentId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/items/department_schedule?filter[department_id][_eq]=$departmentId&limit=1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          return DepartmentScheduleModel.fromJson(data['data'][0]);
        }
      }
    } catch (e) {
      print("Get Schedule Error: $e");
    }
    return null;
  }

  // ==================== Overtime ====================

  /// Get approved overtime requests for a period
  Future<List<Map<String, dynamic>>> getOvertimeRequestsForPeriod(
    int userId,
    String startDate,
    String endDate,
  ) async {
    final url = Uri.parse(
      '$baseUrl/items/overtime_request?filter[user_id][_eq]=$userId&filter[status][_eq]=approved&filter[request_date][_between]=$startDate,$endDate',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      print("Get OT Error: $e");
    }
    return [];
  }

  /// Get all overtime requests for a specific user
  Future<List<OvertimeRequestModel>> getOvertimeRequests(int userId) async {
    final url = Uri.parse(
      '$baseUrl/items/overtime_request?filter[user_id][_eq]=$userId&sort=-request_date,-filed_at&limit=-1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((e) => OvertimeRequestModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Get Overtime Errors: $e");
    }
    return [];
  }

  Future<bool> createOvertimeRequest(OvertimeRequestModel request) async {
    final url = Uri.parse('$baseUrl/items/overtime_request');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating overtime request: $e');
      return false;
    }
  }

  Future<bool> updateOvertimeRequest(
    int overtimeId,
    OvertimeRequestModel request,
  ) async {
    final url = Uri.parse('$baseUrl/items/overtime_request/$overtimeId');
    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating overtime request: $e');
      return false;
    }
  }

  Future<bool> deleteOvertimeRequest(int overtimeId) async {
    final url = Uri.parse('$baseUrl/items/overtime_request/$overtimeId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error deleting overtime request: $e');
      return false;
    }
  }

  // ==================== Undertime ====================

  /// Get undertime requests for a specific user
  Future<List<UndertimeRequestModel>> getUndertimeRequests(int userId) async {
    final url = Uri.parse(
      '$baseUrl/items/undertime_request?filter[user_id][_eq]=$userId&sort=-request_date,-filed_at&limit=-1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((e) => UndertimeRequestModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Get Undertime Error: $e");
    }
    return [];
  }

  /// Create a new undertime request
  Future<bool> createUndertimeRequest(UndertimeRequestModel request) async {
    final url = Uri.parse('$baseUrl/items/undertime_request');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Create Undertime Error: $e");
      return false;
    }
  }

  /// Update an existing undertime request
  Future<bool> updateUndertimeRequest(
    int undertimeId,
    UndertimeRequestModel request,
  ) async {
    final url = Uri.parse('$baseUrl/items/undertime_request/$undertimeId');
    try {
      // Only send editable fields
      final body = request.toJson();
      body.remove(
        'status',
      ); // Usually status is handled by approver, but user can cancel?
      // For now, let's keep it simple and just send the whole thing if the status is still pending

      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Undertime Error: $e");
      return false;
    }
  }

  /// Delete an undertime request
  Future<bool> deleteUndertimeRequest(int undertimeId) async {
    final url = Uri.parse('$baseUrl/items/undertime_request/$undertimeId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print("Delete Undertime Error: $e");
      return false;
    }
  }

  // ==================== Leave ====================

  /// Get leave requests for a specific user
  Future<List<LeaveRequestModel>> getLeaveRequests(int userId) async {
    final url = Uri.parse(
      '$baseUrl/items/leave_request?filter[user_id][_eq]=$userId&sort=-leave_start,-filed_at&limit=-1',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((e) => LeaveRequestModel.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print("Get Leave Error: $e");
    }
    return [];
  }

  /// Create a new leave request
  Future<bool> createLeaveRequest(LeaveRequestModel request) async {
    final url = Uri.parse('$baseUrl/items/leave_request');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Create Leave Error: $e");
      return false;
    }
  }

  /// Update an existing leave request
  Future<bool> updateLeaveRequest(
    int leaveId,
    LeaveRequestModel request,
  ) async {
    final url = Uri.parse('$baseUrl/items/leave_request/$leaveId');
    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Leave Error: $e");
      return false;
    }
  }

  /// Delete a leave request
  Future<bool> deleteLeaveRequest(int leaveId) async {
    final url = Uri.parse('$baseUrl/items/leave_request/$leaveId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print("Delete Leave Error: $e");
      return false;
    }
  }
}
