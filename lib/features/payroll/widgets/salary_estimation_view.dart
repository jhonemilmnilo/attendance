import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/salary_service.dart';
import '../../../core/theme/shadcn_ui.dart';

class SalaryEstimationView extends StatefulWidget {
  final UserModel user;

  const SalaryEstimationView({super.key, required this.user});

  @override
  State<SalaryEstimationView> createState() => _SalaryEstimationViewState();
}

class _SalaryEstimationViewState extends State<SalaryEstimationView> {
  final SalaryService _salaryService = SalaryService();
  bool _isLoading = true;
  List<SalaryEstimation> _pendingEstimations = [];
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
      final estimations = await _salaryService.getRecentEstimations(widget.user);

      if (mounted) {
        setState(() {
          _pendingEstimations = estimations;
          _isLoading = false;
          if (_selectedPeriodIndex >= estimations.length) {
            _selectedPeriodIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint("Estimation Error: $e");
      if (mounted) {
        setState(() {
          _error = "An error occurred while loading estimations.";
          _isLoading = false;
        });
      }
    }
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

  Widget _buildSummaryCard(SalaryEstimation p, NumberFormat formatter) {
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
