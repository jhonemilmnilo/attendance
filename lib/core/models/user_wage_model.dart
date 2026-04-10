/// Model representing the user_wage_management table data
class UserWageModel {
  final int id;
  final int userId;
  final double dailyWage;
  final int? scheduleId;
  final DateTime? cutoffWageDateUpdate;
  final double philhealthMonthly;
  final double sssMonthly;
  final double pagibigMonthly;
  final bool isCard;
  final bool isRegularEmployee;
  final int vacationLeavePerYear;
  final int sick_leave_per_year;
  final bool paidHoliday;

  UserWageModel({
    required this.id,
    required this.userId,
    required this.dailyWage,
    this.scheduleId,
    this.cutoffWageDateUpdate,
    this.philhealthMonthly = 0.0,
    this.sssMonthly = 0.0,
    this.pagibigMonthly = 0.0,
    this.isCard = false,
    this.isRegularEmployee = false,
    this.vacationLeavePerYear = 0,
    this.sick_leave_per_year = 0,
    this.paidHoliday = false,
  });

  factory UserWageModel.fromJson(Map<String, dynamic> json) {
    return UserWageModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      dailyWage: (json['daily_wage'] ?? 0.0).toDouble(),
      scheduleId: json['schedule_id'],
      cutoffWageDateUpdate: json['cutoff_wage_date_update'] != null
          ? DateTime.parse(json['cutoff_wage_date_update'])
          : null,
      philhealthMonthly: (json['philhealth_contribution_monthly'] ?? 0.0).toDouble(),
      sssMonthly: (json['sss_contribution_monthly'] ?? 0.0).toDouble(),
      pagibigMonthly: (json['pagibig_contribution_monthly'] ?? 0.0).toDouble(),
      isCard: json['isCard'] == 1 || json['isCard'] == true,
      isRegularEmployee: json['isRegularEmployee'] == 1 || json['isRegularEmployee'] == true,
      vacationLeavePerYear: json['vacation_leave_per_year'] ?? 0,
      sick_leave_per_year: json['sick_leave_per_year'] ?? 0,
      paidHoliday: json['paid_holiday'] == 1 || json['paid_holiday'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_wage': dailyWage,
      'schedule_id': scheduleId,
      'cutoff_wage_date_update': cutoffWageDateUpdate?.toIso8601String(),
      'philhealth_contribution_monthly': philhealthMonthly,
      'sss_contribution_monthly': sssMonthly,
      'pagibig_contribution_monthly': pagibigMonthly,
      'isCard': isCard ? 1 : 0,
      'isRegularEmployee': isRegularEmployee ? 1 : 0,
      'vacation_leave_per_year': vacationLeavePerYear,
      'sick_leave_per_year': sick_leave_per_year,
      'paid_holiday': paidHoliday ? 1 : 0,
    };
  }
}
