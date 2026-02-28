import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../core/models/payroll_employee_model.dart';

class PayslipDetailScreen extends StatelessWidget {
  final PayrollEmployeeModel payroll;

  const PayslipDetailScreen({super.key, required this.payroll});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Digital Payslip',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 20),
            onPressed: () {
              // Share logic could go here
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          children: [
            _buildNetPayHeader(currencyFormat),
            const SizedBox(height: 16),
            _buildEmployeeInfo(),
            const SizedBox(height: 16),
            _buildWorkStatsSection(),
            const SizedBox(height: 16),
            _buildBreakdownSection('Earnings', _getEarnings(currencyFormat)),
            const SizedBox(height: 16),
            _buildBreakdownSection(
              'Deductions',
              _getDeductions(currencyFormat),
              isDeduction: true,
            ),
            const SizedBox(height: 16),
            _buildFooter(dateFormat),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNetPayHeader(NumberFormat currencyFormat) {
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          Text(
            currencyFormat.format(payroll.netPay ?? 0.0),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'TOTAL NET PAY',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 100.ms);
  }

  Widget _buildEmployeeInfo() {
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.user, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payroll.employeeName ?? 'Employee Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${payroll.positionName ?? 'Position'} • ID: ${payroll.userId}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem(
                'DEPARTMENT',
                payroll.departmentNameSnapshot ?? 'N/A',
              ),
              _buildInfoItem('PAY PERIOD', payroll.cutoffLabel ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Days Worked',
            '${payroll.totalDaysWorked}',
            LucideIcons.calendarCheck2,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Hours',
            '${payroll.totalHoursWorked}',
            LucideIcons.clock4,
            const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Late/UT',
            '${payroll.lateMinutes + payroll.undertimeMinutes}m',
            LucideIcons.timerOff,
            const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return ShadCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(
    String title,
    List<Map<String, dynamic>> items, {
    bool isDeduction = false,
  }) {
    double total = 0;
    for (var item in items) {
      total += (item['value'] as double).abs();
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                  color: Color(0xFF334155),
                ),
              ),
              Text(
                NumberFormat.currency(
                  symbol: '₱',
                  decimalDigits: 2,
                ).format(total),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isDeduction
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items
              .where((i) => (i['value'] as double).abs() > 0)
              .map(
                (item) => _buildBreakdownRow(
                  item['label'],
                  item['value'],
                  isDeduction: isDeduction,
                  subtitle: item['subtitle'],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double value, {
    required bool isDeduction,
    String? subtitle,
  }) {
    final format = NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            (isDeduction ? '-' : '+') +
                format.format(value.abs()).replaceAll('₱', '₱ '),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDeduction
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getEarnings(NumberFormat format) {
    return [
      {
        'label': 'Basic Pay',
        'value': payroll.basicPay,
        'subtitle':
            '${payroll.dailyRate}/day x ${payroll.totalDaysWorked} days',
      },
      if (payroll.otAmount > 0)
        {
          'label': 'Overtime Pay',
          'value': payroll.otAmount,
          'subtitle': '${payroll.overtimeMinutes} mins worked',
        },
      if (payroll.holidayPay > 0)
        {
          'label': 'Holiday Pay',
          'value': payroll.holidayPay,
          'subtitle': '${payroll.holidayDays} holidays',
        },
      if (payroll.nightDiffAmount > 0)
        {
          'label': 'Night Diff',
          'value': payroll.nightDiffAmount,
          'subtitle': '${payroll.nightDiffMinutes} mins',
        },
      if (payroll.allowance > 0)
        {'label': 'Allowance', 'value': payroll.allowance},
      if (payroll.retroPay > 0)
        {
          'label': 'Retro Pay',
          'value': payroll.retroPay,
          'subtitle': payroll.retroRemarks,
        },
      if (payroll.manualAdditions > 0)
        {'label': 'Manual Adj.', 'value': payroll.manualAdditions},
    ];
  }

  List<Map<String, dynamic>> _getDeductions(NumberFormat format) {
    return [
      if (payroll.benefitSss > 0)
        {'label': 'SSS Contribution', 'value': payroll.benefitSss},
      if (payroll.benefitPhilhealth > 0)
        {'label': 'PhilHealth', 'value': payroll.benefitPhilhealth},
      if (payroll.benefitPagibig > 0)
        {'label': 'Pag-IBIG', 'value': payroll.benefitPagibig},
      if (payroll.benefitLoanSss > 0)
        {'label': 'SSS Loan', 'value': payroll.benefitLoanSss},
      if (payroll.benefitLoanPagibig > 0)
        {'label': 'Pag-IBIG Loan', 'value': payroll.benefitLoanPagibig},
      if (payroll.loanCar > 0) {'label': 'Car Loan', 'value': payroll.loanCar},
      if (payroll.loanCoop > 0)
        {'label': 'Coop Loan', 'value': payroll.loanCoop},
      if (payroll.loanVale > 0)
        {'label': 'Vale / Cash Advance', 'value': payroll.loanVale},
      if (payroll.coopSavings > 0)
        {'label': 'Coop Savings', 'value': payroll.coopSavings},
      if (payroll.lateDeduction > 0)
        {
          'label': 'Late',
          'value': payroll.lateDeduction,
          'subtitle': '${payroll.lateMinutes} mins',
        },
      if (payroll.undertimeDeduction > 0)
        {
          'label': 'Undertime',
          'value': payroll.undertimeDeduction,
          'subtitle': '${payroll.undertimeMinutes} mins',
        },
      if (payroll.shortageDeduction > 0)
        {'label': 'Shortage', 'value': payroll.shortageDeduction},
      if (payroll.manualDeductions > 0)
        {'label': 'Manual Adj.', 'value': payroll.manualDeductions},
    ];
  }

  Widget _buildFooter(DateFormat dateFormat) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'This is a system-generated document.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        Text(
          'Generated on ${dateFormat.format(DateTime.now())}',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        const SizedBox(height: 24),
        Container(height: 1, width: 80, color: const Color(0xFFE2E8F0)),
      ],
    );
  }
}
