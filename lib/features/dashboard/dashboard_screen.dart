import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/attendance_log_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';
import '../payroll/payroll_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final Function(int)? onAction;

  const DashboardScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.onAction,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  AttendanceLogModel? _currentLog;
  UserModel? _fullUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (_currentLog == null) {
      setState(() => _isLoading = true);
    }
    await Future.wait([_fetchTodayLog(), _fetchUserInfo()]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserInfo() async {
    final user = await _api.getUser(widget.userId);
    if (mounted && user != null) {
      setState(() => _fullUser = user);
    }
  }

  Future<void> _fetchTodayLog() async {
    final log = await _api.getTodayLog(widget.userId);
    if (mounted) {
      setState(() {
        _currentLog = log;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeSection().animate().fadeIn().slideX(begin: -0.1),
                const SizedBox(height: 32),
                _isLoading
                    ? _buildStatusCardSkeleton()
                    : _buildStatusCard()
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 32),
                _isLoading
                    ? _buildTodaySummarySkeleton()
                    : _buildTodaySummary()
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${widget.userName}",
                style: ShadTheme.of(context).textTheme.h2.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: ShadTheme.of(
                      context,
                    ).textTheme.muted.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_currentLog == null) {
      statusText = 'Not Clocked In';
      statusColor = AppColors.mutedForeground;
      statusIcon = LucideIcons.clock;
    } else if (_currentLog!.timeOut != null) {
      statusText = 'Clocked Out';
      statusColor = AppColors.destructive;
      statusIcon = LucideIcons.logOut;
    } else if (_currentLog!.lunchStart != null &&
        _currentLog!.lunchEnd == null) {
      statusText = 'On Lunch';
      statusColor = AppColors.warning;
      statusIcon = LucideIcons.utensils;
    } else if (_currentLog!.breakStart != null &&
        _currentLog!.breakEnd == null) {
      statusText = 'On Break';
      statusColor = AppColors.warning;
      statusIcon = LucideIcons.coffee;
    } else {
      statusText = 'Working';
      statusColor = AppColors.success;
      statusIcon = LucideIcons.briefcase;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(statusIcon, size: 32, color: statusColor),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 3.seconds,
                color: Colors.white.withOpacity(0.5),
              ),
          const SizedBox(height: 20),
          Text(
            "Current Status",
            style: ShadTheme.of(context).textTheme.muted.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText.toUpperCase(),
            style: ShadTheme.of(context).textTheme.h3.copyWith(
              color: statusColor,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "Quick Actions",
            style: ShadTheme.of(context).textTheme.large.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: LucideIcons.timer,
                label: 'Time Log',
                subtitle: 'Check In/Out',
                color: Colors.blue,
                onTap: () => widget.onAction?.call(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: LucideIcons.history,
                label: 'History',
                subtitle: 'View Logs',
                color: Colors.purple,
                onTap: () => widget.onAction?.call(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          icon: LucideIcons.banknote,
          label: 'Payroll',
          subtitle: 'View Payslips & Salary History',
          color: Colors.green,
          onTap: () async {
            if (_fullUser == null) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PayrollHistoryScreen(user: _fullUser!),
              ),
            );
            _fetchData();
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: glassDecoration(opacity: 0.9).copyWith(
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: ShadTheme.of(context).textTheme.small.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: ShadTheme.of(
                context,
              ).textTheme.muted.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            "Today's Overview",
            style: ShadTheme.of(context).textTheme.large.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                "Clock In",
                _currentLog?.formattedTimeIn ?? '--:--',
                LucideIcons.logIn,
                AppColors.success,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(height: 1, color: AppColors.border),
              ),
              _buildSummaryRow(
                "Clock Out",
                _currentLog?.formattedTimeOut ?? '--:--',
                LucideIcons.logOut,
                AppColors.destructive,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: ShadTheme.of(
              context,
            ).textTheme.muted.copyWith(fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: ShadTheme.of(context).textTheme.small.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCardSkeleton() {
    return Container(
          height: 220,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 180,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.4));
  }

  Widget _buildTodaySummarySkeleton() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 20,
              margin: const EdgeInsets.only(left: 4, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
            ),
          ],
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: Colors.grey.withAlpha(20));
  }
}
