import 'package:intl/intl.dart';
import '../models/attendance_log_model.dart';
import '../models/user_model.dart';
import '../utils/salary_calculator.dart';
import 'api_service.dart';

class SalaryEstimation {
  final DateTime start;
  final DateTime end;
  final String label;
  final double totalPay;
  final List<Map<String, dynamic>> dailyLogs;

  SalaryEstimation({
    required this.start,
    required this.end,
    required this.label,
    required this.totalPay,
    this.dailyLogs = const [],
  });
}

class SalaryService {
  final ApiService _api = ApiService();

  /// Gets the salary estimation for the current active cutoff period.
  Future<SalaryEstimation?> getCurrentPeriodEstimation(UserModel user) async {
    try {
      final now = DateTime.now();
      final periods = _generateCheckPeriods(now, 1);
      if (periods.isEmpty) return null;

      final currentPeriod = periods.first;
      return await _estimateForPeriod(user, currentPeriod);
    } catch (e) {
      print("Error estimating current period salary: $e");
      return null;
    }
  }

  /// Gets salary estimations for a specific number of periods (e.g. current + previous).
  Future<List<SalaryEstimation>> getRecentEstimations(UserModel user, {int count = 3}) async {
    try {
      final now = DateTime.now();
      final periods = _generateCheckPeriods(now, count);
      final payrolls = await _api.getPayrollHistory(user.userId);
      
      List<SalaryEstimation> estimations = [];

      for (var p in periods) {
        // Check if this period exists in recorded payroll
        bool isRecorded = payrolls.any((pr) {
          return pr.cutoffStart.year == p['start']!.year &&
              pr.cutoffStart.month == p['start']!.month &&
              pr.cutoffStart.day == p['start']!.day &&
              pr.cutoffEnd.year == p['end']!.year &&
              pr.cutoffEnd.month == p['end']!.month &&
              pr.cutoffEnd.day == p['end']!.day;
        });

        if (!isRecorded) {
          final estimation = await _estimateForPeriod(user, p);
          if (estimation != null) {
            estimations.add(estimation);
          }
        }
      }
      return estimations;
    } catch (e) {
      print("Error getting recent estimations: $e");
      return [];
    }
  }

  Future<SalaryEstimation?> _estimateForPeriod(UserModel user, Map<String, DateTime> period) async {
    final start = period['start']!;
    final end = period['end']!;
    
    final schedule = await _api.getDepartmentSchedule(user.departmentId);
    final payrolls = await _api.getPayrollHistory(user.userId);
    final userWage = await _api.getUserWage(user.userId);
    
    if (schedule == null || userWage == null) return null;

    // Calculate dynamic hourly rate based on scheduled hours
    // (Total Shift Minutes - 60 mins lunch) / 60 = Total Scheduled Work Hours
    final shiftDuration = DateTime(2024, 1, 1, schedule.workEnd.hour, schedule.workEnd.minute)
        .difference(DateTime(2024, 1, 1, schedule.workStart.hour, schedule.workStart.minute))
        .inMinutes;
    
    final scheduledWorkMinutes = shiftDuration - 60;
    
    // Safety check: Fallback to 8 hours (480 mins) if schedule is zero or negative
    final divisorMinutes = scheduledWorkMinutes > 0 ? scheduledWorkMinutes : 480;
    final hourlyRate = userWage.dailyWage / (divisorMinutes / 60.0);

    final calculator = SalaryCalculator(
      hourlyRate: hourlyRate,
      schedule: schedule,
    );

    final logs = await _api.getHistory(user.userId, limit: 100);
    final otRequests = await _api.getOvertimeRequestsForPeriod(
      user.userId,
      DateFormat('yyyy-MM-dd').format(start),
      DateFormat('yyyy-MM-dd').format(end),
    );

    double total = 0.0;
    List<Map<String, dynamic>> breakdown = [];

    final periodLogs = logs.where((l) {
      try {
        final logDate = DateTime.parse(l.logDate);
        final d = DateTime(logDate.year, logDate.month, logDate.day);
        final s = DateTime(start.year, start.month, start.day);
        final e = DateTime(end.year, end.month, end.day);

        return (d.isAtSameMomentAs(s) || d.isAfter(s)) &&
               (d.isAtSameMomentAs(e) || d.isBefore(e)) &&
               l.timeOut != null;
      } catch (_) {
        return false;
      }
    }).toList();

    for (final log in periodLogs) {
      final result = calculator.calculateDaily(log, otRequests);
      total += result['netPay'];
      breakdown.add({
        'date': log.formattedDate,
        'grossBasicPay': result['grossBasicPay'],
        'netPay': result['netPay'],
        'late': result['lateMinutes'],
        'lateDeduction': result['lateDeduction'],
        'ot': result['otMinutes'],
        'otPay': result['otPay'],
        'undertime': result['undertimeMinutes'],
        'undertimeDeduction': result['undertimeDeduction'],
      });
    }

    final label = "${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}";

    return SalaryEstimation(
      start: start,
      end: end,
      label: label,
      totalPay: total,
      dailyLogs: breakdown,
    );
  }

  List<Map<String, DateTime>> _generateCheckPeriods(DateTime from, int count) {
    List<Map<String, DateTime>> results = [];
    DateTime current = from;

    for (int i = 0; i < count; i++) {
      DateTime start;
      DateTime end;

      if (current.day >= 11 && current.day <= 25) {
        start = DateTime(current.year, current.month, 11);
        end = DateTime(current.year, current.month, 25);
      } else if (current.day >= 26) {
        start = DateTime(current.year, current.month, 26);
        end = DateTime(current.year, current.month + 1, 10);
      } else {
        start = DateTime(current.year, current.month - 1, 26);
        end = DateTime(current.year, current.month, 10);
      }

      // Check if duplicate before adding
      bool exists = results.any((r) => 
        r['start']!.year == start.year && 
        r['start']!.month == start.month && 
        r['start']!.day == start.day
      );

      if (!exists) {
        results.add({'start': start, 'end': end});
      }

      current = start.subtract(const Duration(days: 1));
    }
    return results;
  }
}
