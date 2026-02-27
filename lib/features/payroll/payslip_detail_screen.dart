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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Digital Payslip'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildReceiptHeader(dateFormat),
            const SizedBox(height: 16),
            _buildWorkStats(),
            const SizedBox(height: 16),
            _buildAmountDetails(currencyFormat),
            const SizedBox(height: 24),
            _buildNetPayFooter(currencyFormat),
            const SizedBox(height: 32),
            _buildHelpText(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptHeader(DateFormat dateFormat) {
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(LucideIcons.landmark, size: 40, color: Colors.indigo),
          const SizedBox(height: 12),
          Text(
            payroll.employeeName ?? 'Employee Name',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            '${payroll.positionName ?? 'Position'} • ${payroll.departmentNameSnapshot ?? 'Department'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderItem('PERIOD', payroll.cutoffLabel ?? 'N/A'),
              _buildHeaderItem(
                'RELEASED',
                dateFormat.format(payroll.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildWorkStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Days Worked',
            '${payroll.totalDaysWorked}',
            LucideIcons.calendarCheck,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Late/Undertime',
            '${payroll.lateMinutes + payroll.undertimeMinutes}m',
            LucideIcons.clockAlert,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return ShadCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDetails(NumberFormat currencyFormat) {
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings & Deductions',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          _buildAmountRow('Basic Pay', payroll.basicPay, currencyFormat),
          if (payroll.otAmount > 0)
            _buildAmountRow('Overtime Pay', payroll.otAmount, currencyFormat),
          if (payroll.holidayPay > 0)
            _buildAmountRow('Holiday Pay', payroll.holidayPay, currencyFormat),
          if (payroll.allowance > 0)
            _buildAmountRow('Allowance', payroll.allowance, currencyFormat),
          if (payroll.retroPay > 0)
            _buildAmountRow('Retro Pay', payroll.retroPay, currencyFormat),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          _buildAmountRow(
            'Gross Pay',
            payroll.grossPay,
            currencyFormat,
            isBold: true,
          ),
          const SizedBox(height: 24),
          const Text(
            'Deductions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          _buildAmountRow(
            'SSS Deduction',
            -payroll.benefitSss,
            currencyFormat,
            isDeduction: true,
          ),
          _buildAmountRow(
            'PhilHealth',
            -payroll.benefitPhilhealth,
            currencyFormat,
            isDeduction: true,
          ),
          _buildAmountRow(
            'Pag-IBIG',
            -payroll.benefitPagibig,
            currencyFormat,
            isDeduction: true,
          ),
          if (payroll.loanTotal > 0)
            _buildAmountRow(
              'Loans & Valé',
              -payroll.loanTotal,
              currencyFormat,
              isDeduction: true,
            ),
          if (payroll.lateDeduction > 0)
            _buildAmountRow(
              'Late Deduction',
              -payroll.lateDeduction,
              currencyFormat,
              isDeduction: true,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          _buildAmountRow(
            'Total Deductions',
            -payroll.totalDeductions,
            currencyFormat,
            isBold: true,
            isDeduction: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double value,
    NumberFormat format, {
    bool isBold = false,
    bool isDeduction = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDeduction && !isBold ? Colors.grey[700] : null,
            ),
          ),
          Text(
            format.format(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isDeduction
                  ? Colors.red[700]
                  : (isBold ? Colors.green[700] : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetPayFooter(NumberFormat currencyFormat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TOTAL NET PAY',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(payroll.netPay ?? 0.0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Transferred to Bank Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText() {
    return Column(
      children: [
        Text(
          'Have questions about your payslip?',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          'Contact the HR or Payroll department.',
          style: TextStyle(
            color: Colors.indigo[400],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}
