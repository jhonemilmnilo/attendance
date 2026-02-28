import 'dart:convert';

class PayrollEmployeeModel {
  final int? id;
  final int userId;
  final String? employeeName;
  final String? position;
  final String? departmentName;
  final String? positionName;
  final String? departmentNameSnapshot;
  final int payrollRunId;
  final String? payrollRunStatus;
  final DateTime cutoffStart;
  final DateTime cutoffEnd;
  final String? cutoffLabel;
  final double dailyRate;
  final String? cutoffType;
  final int? cutoffId;
  final double basicDailyRate;
  final double hourlyRate;
  final double monthlyRate;
  final double totalDaysWorked;
  final int totalWorkMinutes;
  final int lateMinutes;
  final int undertimeMinutes;
  final int overtimeMinutes;
  final int nightDiffMinutes;
  final double totalHoursWorked;
  final double basicPay;
  final double otAmount;
  final double leaveAmount;
  final double retroPay;
  final String? retroRemarks;
  final double holiday;
  final double holidayPay;
  final double holidayDays;
  final double restDayAmount;
  final double nightDiffAmount;
  final double allowance;
  final double manualAdditions;
  final double lateDeduction;
  final double undertimeDeduction;
  final double shortageDeduction;
  final double benefitPagibig;
  final double loanVale;
  final double loanCar;
  final double loanCoop;
  final double loanTotal;
  final double benefitPhilhealth;
  final double benefitSss;
  final double benefitLoanSss;
  final double benefitLoanPagibig;
  final double benefitLoanTotal;
  final double coopSavings;
  final double coopLoan;
  final double drDeduction;
  final double otherDeductions;
  final double manualDeductions;
  final double totalAdditions;
  final double totalDeductions;
  final double grossPay;
  final double? netPay;
  final bool isProrated;
  final Map<String, dynamic>? prorationJson;
  final Map<String, dynamic>? breakdownJson;
  final double previousNetPay;
  final double varianceAmountUi;
  final double varianceAmount;
  final double variancePct;
  final bool varianceFlag;
  final bool onHold;
  final bool isCard;
  final DateTime createdAt;
  final int? createdBy;
  final DateTime? updatedDate;
  final int? updatedBy;

  PayrollEmployeeModel({
    this.id,
    required this.userId,
    this.employeeName,
    this.position,
    this.departmentName,
    this.positionName,
    this.departmentNameSnapshot,
    required this.payrollRunId,
    required this.cutoffStart,
    required this.cutoffEnd,
    this.cutoffLabel,
    this.dailyRate = 0.0,
    this.cutoffType,
    this.cutoffId,
    this.basicDailyRate = 0.0,
    this.hourlyRate = 0.0,
    this.monthlyRate = 0.0,
    this.totalDaysWorked = 0.0,
    this.totalWorkMinutes = 0,
    this.lateMinutes = 0,
    this.undertimeMinutes = 0,
    this.overtimeMinutes = 0,
    this.nightDiffMinutes = 0,
    this.totalHoursWorked = 0.0,
    this.basicPay = 0.0,
    this.otAmount = 0.0,
    this.leaveAmount = 0.0,
    this.retroPay = 0.0,
    this.retroRemarks,
    this.holiday = 0.0,
    this.holidayPay = 0.0,
    this.holidayDays = 0.0,
    this.restDayAmount = 0.0,
    this.nightDiffAmount = 0.0,
    this.allowance = 0.0,
    this.manualAdditions = 0.0,
    this.lateDeduction = 0.0,
    this.undertimeDeduction = 0.0,
    this.shortageDeduction = 0.0,
    this.benefitPagibig = 0.0,
    this.loanVale = 0.0,
    this.loanCar = 0.0,
    this.loanCoop = 0.0,
    this.loanTotal = 0.0,
    this.benefitPhilhealth = 0.0,
    this.benefitSss = 0.0,
    this.benefitLoanSss = 0.0,
    this.benefitLoanPagibig = 0.0,
    this.benefitLoanTotal = 0.0,
    this.coopSavings = 0.0,
    this.coopLoan = 0.0,
    this.drDeduction = 0.0,
    this.otherDeductions = 0.0,
    this.manualDeductions = 0.0,
    this.totalAdditions = 0.0,
    this.totalDeductions = 0.0,
    this.grossPay = 0.0,
    this.netPay = 0.0,
    this.isProrated = false,
    this.prorationJson,
    this.breakdownJson,
    this.previousNetPay = 0.0,
    this.varianceAmountUi = 0.0,
    this.varianceAmount = 0.0,
    this.variancePct = 0.0,
    this.varianceFlag = false,
    this.onHold = false,
    this.isCard = false,
    required this.createdAt,
    this.createdBy,
    this.updatedDate,
    this.updatedBy,
    this.payrollRunStatus,
  });

  factory PayrollEmployeeModel.fromJson(Map<String, dynamic> json) {
    int runId = 0;
    String? runStatus;
    if (json['payroll_run_id'] is Map) {
      runId = json['payroll_run_id']['payroll_run_id'] ?? 0;
      runStatus = json['payroll_run_id']['status'];
    } else {
      runId = json['payroll_run_id'] ?? 0;
    }

    return PayrollEmployeeModel(
      id: json['id'],
      userId: json['user_id'],
      employeeName: json['employee_name'],
      position: json['position'],
      departmentName: json['department_name'],
      positionName: json['position_name'],
      departmentNameSnapshot: json['department_name_snapshot'],
      payrollRunId: runId,
      payrollRunStatus: runStatus,
      cutoffStart: DateTime.parse(json['cutoff_start']),
      cutoffEnd: DateTime.parse(json['cutoff_end']),
      cutoffLabel: json['cutoff_label'],
      dailyRate: (json['daily_rate'] ?? 0.0).toDouble(),
      cutoffType: json['cutoff_type'],
      cutoffId: json['cutoff_id'],
      basicDailyRate: (json['basic_daily_rate'] ?? 0.0).toDouble(),
      hourlyRate: (json['hourly_rate'] ?? 0.0).toDouble(),
      monthlyRate: (json['monthly_rate'] ?? 0.0).toDouble(),
      totalDaysWorked: (json['total_days_worked'] ?? 0.0).toDouble(),
      totalWorkMinutes: json['total_work_minutes'] ?? 0,
      lateMinutes: json['late_minutes'] ?? 0,
      undertimeMinutes: json['undertime_minutes'] ?? 0,
      overtimeMinutes: json['overtime_minutes'] ?? 0,
      nightDiffMinutes: json['night_diff_minutes'] ?? 0,
      totalHoursWorked: (json['total_hours_worked'] ?? 0.0).toDouble(),
      basicPay: (json['basic_pay'] ?? 0.0).toDouble(),
      otAmount: (json['ot_amount'] ?? 0.0).toDouble(),
      leaveAmount: (json['leave_amount'] ?? 0.0).toDouble(),
      retroPay: (json['retro_pay'] ?? 0.0).toDouble(),
      retroRemarks: json['retro_remarks'],
      holiday: (json['holiday'] ?? 0.0).toDouble(),
      holidayPay: (json['holiday_pay'] ?? 0.0).toDouble(),
      holidayDays: (json['holiday_days'] ?? 0.0).toDouble(),
      restDayAmount: (json['rest_day_amount'] ?? 0.0).toDouble(),
      nightDiffAmount: (json['night_diff_amount'] ?? 0.0).toDouble(),
      allowance: (json['allowance'] ?? 0.0).toDouble(),
      manualAdditions: (json['manual_additions'] ?? 0.0).toDouble(),
      lateDeduction: (json['late_deduction'] ?? 0.0).toDouble(),
      undertimeDeduction: (json['undertime_deduction'] ?? 0.0).toDouble(),
      shortageDeduction: (json['shortage_deduction'] ?? 0.0).toDouble(),
      benefitPagibig: (json['benefit_pagibig'] ?? 0.0).toDouble(),
      loanVale: (json['loan_vale'] ?? 0.0).toDouble(),
      loanCar: (json['loan_car'] ?? 0.0).toDouble(),
      loanCoop: (json['loan_coop'] ?? 0.0).toDouble(),
      loanTotal: (json['loan_total'] ?? 0.0).toDouble(),
      benefitPhilhealth: (json['benefit_philhealth'] ?? 0.0).toDouble(),
      benefitSss: (json['benefit_sss'] ?? 0.0).toDouble(),
      benefitLoanSss: (json['benefit_loan_sss'] ?? 0.0).toDouble(),
      benefitLoanPagibig: (json['benefit_loan_pagibig'] ?? 0.0).toDouble(),
      benefitLoanTotal: (json['benefit_loan_total'] ?? 0.0).toDouble(),
      coopSavings: (json['coop_savings'] ?? 0.0).toDouble(),
      coopLoan: (json['coop_loan'] ?? 0.0).toDouble(),
      drDeduction: (json['dr_deduction'] ?? 0.0).toDouble(),
      otherDeductions: (json['other_deductions'] ?? 0.0).toDouble(),
      manualDeductions: (json['manual_deductions'] ?? 0.0).toDouble(),
      totalAdditions: (json['total_additions'] ?? 0.0).toDouble(),
      totalDeductions: (json['total_deductions'] ?? 0.0).toDouble(),
      grossPay: (json['gross_pay'] ?? 0.0).toDouble(),
      netPay: (json['net_pay'] ?? 0.0).toDouble(),
      isProrated: json['is_prorated'] == 1 || json['is_prorated'] == true,
      prorationJson: json['proration_json'] != null
          ? jsonDecode(
              json['proration_json'] is String
                  ? json['proration_json']
                  : jsonEncode(json['proration_json']),
            )
          : null,
      breakdownJson: json['breakdown_json'] != null
          ? jsonDecode(
              json['breakdown_json'] is String
                  ? json['breakdown_json']
                  : jsonEncode(json['breakdown_json']),
            )
          : null,
      previousNetPay: (json['previous_net_pay'] ?? 0.0).toDouble(),
      varianceAmountUi: (json['variance_amount_ui'] ?? 0.0).toDouble(),
      varianceAmount: (json['variance_amount'] ?? 0.0).toDouble(),
      variancePct: (json['variance_pct'] ?? 0.0).toDouble(),
      varianceFlag: json['variance_flag'] == 1 || json['variance_flag'] == true,
      onHold: json['on_hold'] == 1 || json['on_hold'] == true,
      isCard: json['is_card'] == 1 || json['is_card'] == true,
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
      updatedDate: json['updated_date'] != null
          ? DateTime.parse(json['updated_date'])
          : null,
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'employee_name': employeeName,
      'position': position,
      'department_name': departmentName,
      'position_name': positionName,
      'department_name_snapshot': departmentNameSnapshot,
      'payroll_run_id': payrollRunId,
      'cutoff_start': cutoffStart.toIso8601String(),
      'cutoff_end': cutoffEnd.toIso8601String(),
      'cutoff_label': cutoffLabel,
      'daily_rate': dailyRate,
      'cutoff_type': cutoffType,
      'cutoff_id': cutoffId,
      'basic_daily_rate': basicDailyRate,
      'hourly_rate': hourlyRate,
      'monthly_rate': monthlyRate,
      'total_days_worked': totalDaysWorked,
      'total_work_minutes': totalWorkMinutes,
      'late_minutes': lateMinutes,
      'undertime_minutes': undertimeMinutes,
      'overtime_minutes': overtimeMinutes,
      'night_diff_minutes': nightDiffMinutes,
      'total_hours_worked': totalHoursWorked,
      'basic_pay': basicPay,
      'ot_amount': otAmount,
      'leave_amount': leaveAmount,
      'retro_pay': retroPay,
      'retro_remarks': retroRemarks,
      'holiday': holiday,
      'holiday_pay': holidayPay,
      'holiday_days': holidayDays,
      'rest_day_amount': restDayAmount,
      'night_diff_amount': nightDiffAmount,
      'allowance': allowance,
      'manual_additions': manualAdditions,
      'late_deduction': lateDeduction,
      'undertime_deduction': undertimeDeduction,
      'shortage_deduction': shortageDeduction,
      'benefit_pagibig': benefitPagibig,
      'loan_vale': loanVale,
      'loan_car': loanCar,
      'loan_coop': loanCoop,
      'loan_total': loanTotal,
      'benefit_philhealth': benefitPhilhealth,
      'benefit_sss': benefitSss,
      'benefit_loan_sss': benefitLoanSss,
      'benefit_loan_pagibig': benefitLoanPagibig,
      'benefit_loan_total': benefitLoanTotal,
      'coop_savings': coopSavings,
      'coop_loan': coopLoan,
      'dr_deduction': drDeduction,
      'other_deductions': otherDeductions,
      'manual_deductions': manualDeductions,
      'total_additions': totalAdditions,
      'total_deductions': totalDeductions,
      'gross_pay': grossPay,
      'net_pay': netPay,
      'is_prorated': isProrated ? 1 : 0,
      'proration_json': prorationJson != null
          ? jsonEncode(prorationJson)
          : null,
      'breakdown_json': breakdownJson != null
          ? jsonEncode(breakdownJson)
          : null,
      'previous_net_pay': previousNetPay,
      'variance_amount_ui': varianceAmountUi,
      'variance_amount': varianceAmount,
      'variance_pct': variancePct,
      'variance_flag': varianceFlag ? 1 : 0,
      'on_hold': onHold ? 1 : 0,
      'is_card': isCard ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_date': updatedDate?.toIso8601String(),
      'updated_by': updatedBy,
    };
  }
}
