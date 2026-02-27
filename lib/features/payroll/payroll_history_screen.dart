import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'widgets/salary_estimation_view.dart';
import '../../core/models/payroll_employee_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import 'payslip_detail_screen.dart';

class PayrollHistoryScreen extends StatefulWidget {
  final UserModel user;

  const PayrollHistoryScreen({super.key, required this.user});

  @override
  State<PayrollHistoryScreen> createState() => _PayrollHistoryScreenState();
}

class _PayrollHistoryScreenState extends State<PayrollHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<PayrollEmployeeModel> _payrollHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchPayrollHistory();
  }

  Future<void> _fetchPayrollHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _apiService.getPayrollHistory(widget.user.userId);
      setState(() {
        _payrollHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Error'),
          description: Text('Failed to fetch payroll history'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payroll'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'History'),
              Tab(text: 'Current Estimation'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryTab(),
            SalaryEstimationView(user: widget.user),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_payrollHistory.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _fetchPayrollHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _payrollHistory.length,
        itemBuilder: (context, index) {
          final item = _payrollHistory[index];
          return _buildPayrollCard(item);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.banknote, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No payroll records found',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(PayrollEmployeeModel item) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PayslipDetailScreen(payroll: item),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.calendarDays, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.cutoffLabel ?? 'Payroll Period',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(item.cutoffStart)} - ${dateFormat.format(item.cutoffEnd)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormat.format(item.netPay ?? 0.0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'Net Pay',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
