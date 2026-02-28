import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/shadcn_ui.dart';
import '../../../core/utils/salary_calculator.dart';

class SalaryEstimationView extends StatefulWidget {
  final UserModel user;

  const SalaryEstimationView({super.key, required this.user});

  @override
  State<SalaryEstimationView> createState() => _SalaryEstimationViewState();
}

class PeriodEstimation {
  final DateTime start;
  final DateTime end;
  final String label;
  double totalPay;
  List<Map<String, dynamic>> dailyLogs;

  PeriodEstimation({
    required this.start,
    required this.end,
    required this.label,
    this.totalPay = 0.0,
    this.dailyLogs = const [],
  });
}

class _SalaryEstimationViewState extends State<SalaryEstimationView> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<PeriodEstimation> _pendingEstimations = [];
  String? _error;
  int _selectedPeriodIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadEstimation();
  }

  Future<void> _loadEstimation() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch common data
      final logs = await _api.getHistory(widget.user.userId, limit: 100);
      final schedule = await _api.getDepartmentSchedule(
        widget.user.departmentId,
      );
      final payrolls = await _api.getPayrollHistory(widget.user.userId);

      if (schedule == null) {
        setState(() {
          _error = "Department schedule not found.";
          _isLoading = false;
        });
        return;
      }

      if (payrolls.isEmpty) {
        setState(() {
          _error = "No payroll history found. Hourly rate is unknown.";
          _isLoading = false;
        });
        return;
      }

      final hourlyRate = payrolls.first.hourlyRate;
      final calculator = SalaryCalculator(
        hourlyRate: hourlyRate,
        schedule: schedule,
      );

      // 2. Generate periods to check (Current + last 2)
      final periods = _generateCheckPeriods(DateTime.now(), 3);
      List<PeriodEstimation> pending = [];

      for (var p in periods) {
        // Check if this period exists in recorded payroll
        bool isRecorded = payrolls.any((pr) {
          // Compare dates (ignoring time)
          return pr.cutoffStart.year == p.start.year &&
              pr.cutoffStart.month == p.start.month &&
              pr.cutoffStart.day == p.start.day &&
              pr.cutoffEnd.year == p.end.year &&
              pr.cutoffEnd.month == p.end.month &&
              pr.cutoffEnd.day == p.end.day;
        });

        if (!isRecorded) {
          // Fetch OT requests for this specific period
          final otRequests = await _api.getOvertimeRequestsForPeriod(
            widget.user.userId,
            DateFormat('yyyy-MM-dd').format(p.start),
            DateFormat('yyyy-MM-dd').format(p.end),
          );

          // Calculate estimations for this period
          double total = 0.0;
          List<Map<String, dynamic>> breakdown = [];

          final periodLogs = logs.where((l) {
            try {
              final logDate = DateTime.parse(l.logDate);
              // Normalize dates for comparison
              final d = DateTime(logDate.year, logDate.month, logDate.day);
              final s = DateTime(p.start.year, p.start.month, p.start.day);
              final e = DateTime(p.end.year, p.end.month, p.end.day);

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
              'netPay': result['netPay'],
              'late': result['lateMinutes'],
              'ot': result['otMinutes'],
              'undertime': result['undertimeMinutes'],
            });
          }

          if (breakdown.isNotEmpty ||
              p.start.isAfter(
                DateTime.now().subtract(const Duration(days: 15)),
              )) {
            p.totalPay = total;
            p.dailyLogs = breakdown;
            pending.add(p);
          }
        }
      }

      setState(() {
        _pendingEstimations = pending;
        _isLoading = false;
        if (_selectedPeriodIndex >= pending.length) {
          _selectedPeriodIndex = 0;
        }
      });
    } catch (e) {
      debugPrint("Estimation Error: $e");
      setState(() {
        _error = "An error occurred while loading estimations.";
        _isLoading = false;
      });
    }
  }

  List<PeriodEstimation> _generateCheckPeriods(DateTime from, int count) {
    List<PeriodEstimation> results = [];
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

      final label =
          "${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(end)}";

      // Check if duplicate before adding
      if (!results.any((r) => r.label == label)) {
        results.add(PeriodEstimation(start: start, end: end, label: label));
      }

      // Move current back to before this period
      current = start.subtract(const Duration(days: 1));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.circleAlert, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ShadButton.outline(
                onPressed: _loadEstimation,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return RefreshIndicator(
      onRefresh: _loadEstimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_pendingEstimations.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "All cutoff periods have been payout and moved to History.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: _pendingEstimations.length,
                  onPageChanged: (i) =>
                      setState(() => _selectedPeriodIndex = i),
                  itemBuilder: (context, index) {
                    final p = _pendingEstimations[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildSummaryCard(p, currencyFormat),
                    );
                  },
                ),
              ),
              if (_pendingEstimations.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pendingEstimations.length, (i) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _selectedPeriodIndex == i
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                "Daily Breakdown",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              if (_pendingEstimations[_selectedPeriodIndex].dailyLogs.isEmpty)
                const Text("No completed attendance logs for this period.")
              else
                ..._pendingEstimations[_selectedPeriodIndex].dailyLogs.map(
                  (day) => _buildDayItem(day, currencyFormat),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(PeriodEstimation p, NumberFormat formatter) {
    return ShadCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            p.label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text("Estimated Net Pay"),
          const SizedBox(height: 12),
          Text(
            formatter.format(p.totalPay),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            p.start.isAfter(DateTime.now().subtract(const Duration(days: 1)))
                ? "Current Active Cutoff"
                : "Pending Payout",
            style: TextStyle(
              fontSize: 12,
              color:
                  p.start.isAfter(
                    DateTime.now().subtract(const Duration(days: 1)),
                  )
                  ? Colors.blue
                  : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(Map<String, dynamic> day, NumberFormat formatter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day['date'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (day['late'] > 0)
                    Text(
                      "Late: ${day['late']}m ",
                      style: const TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  if (day['ot'] > 0)
                    Text(
                      "OT: ${day['ot']}m ",
                      style: const TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  if (day['undertime'] > 0)
                    Text(
                      "UT: ${day['undertime']}m ",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Text(
            formatter.format(day['netPay']),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
