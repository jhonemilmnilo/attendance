import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'widgets/salary_estimation_view.dart';
import '../../core/models/payroll_employee_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';
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
  List<PayrollEmployeeModel> _draftPayrolls = [];

  @override
  void initState() {
    super.initState();
    _fetchPayrollHistory();
  }

  Future<void> _fetchPayrollHistory() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getPayrollHistory(widget.user.userId),
        _apiService.getDraftPayrolls(widget.user.userId),
      ]);
      setState(() {
        _payrollHistory = results[0];
        _draftPayrolls = results[1];
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          automaticallyImplyLeading: false,
          title: const Text('Payroll'),
          centerTitle: true,
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Draft'),
                    if (_draftPayrolls.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_draftPayrolls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'History'),
              const Tab(text: 'Current Estimation'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDraftTab(),
            _buildHistoryTab(),
            SalaryEstimationView(user: widget.user),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_draftPayrolls.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.fileClock,
        message: 'No draft payrolls',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPayrollHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _draftPayrolls.length,
        itemBuilder: (context, index) {
          final item = _draftPayrolls[index];
          return _buildPayrollCard(item, isDraft: true);
        },
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

  Widget _buildEmptyState({IconData? icon, String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon ?? LucideIcons.banknote, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message ?? 'No payroll records found',
            style: TextStyle(color: Colors.grey[600], fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollCard(PayrollEmployeeModel item, {bool isDraft = false}) {
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
                  color: (isDraft ? Colors.orange : Colors.blue).withOpacity(
                    0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDraft ? LucideIcons.fileClock : LucideIcons.calendarDays,
                  color: isDraft ? Colors.orange : Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.cutoffLabel ?? 'Payroll Period',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (isDraft) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.2),
                              ),
                            ),
                            child: const Text(
                              'DRAFT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDraft ? Colors.orange : Colors.green,
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
