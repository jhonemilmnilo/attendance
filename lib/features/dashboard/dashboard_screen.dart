import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/attendance_log_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';

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

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId && widget.userId != 0) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (_currentLog == null) {
      setState(() => _isLoading = true);
    }
    await _fetchTodayLog();
    if (mounted) {
      setState(() => _isLoading = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildWelcomeSection().animate().fadeIn().slideX(begin: -0.1),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isLoading
                      ? _buildStatusCardSkeleton(
                          key: const ValueKey('skeleton_status'),
                        )
                      : _buildStatusCard(
                          key: const ValueKey('data_status'),
                        ).animate().fadeIn(),
                ),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  child: _isLoading
                      ? _buildTodaySummarySkeleton(
                          key: const ValueKey('skeleton_summary'),
                        )
                      : _buildTodaySummary(
                          key: const ValueKey('data_summary'),
                        ).animate().fadeIn().slideY(begin: 0.1),
                ),
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

  Widget _buildStatusCard({Key? key}) {
    String statusText;
    Color statusColor;
    IconData statusIcon;
    String statusSubtitle;

    final status = _currentLog?.currentStatus ?? AttendanceStatus.notClockedIn;

    switch (status) {
      case AttendanceStatus.notClockedIn:
        statusText = 'Not Clocked In';
        statusSubtitle = 'Start your shift today';
        statusColor = AppColors.mutedForeground;
        statusIcon = LucideIcons.clock;
        break;
      case AttendanceStatus.clockedOut:
        statusText = 'Clocked Out';
        statusSubtitle = 'Good work today!';
        statusColor = AppColors.destructive;
        statusIcon = LucideIcons.logOut;
        break;
      case AttendanceStatus.onLunch:
        statusText = 'On Lunch';
        statusSubtitle = 'Enjoy your meal';
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.utensils;
        break;
      case AttendanceStatus.onBreak:
        statusText = 'On Break';
        statusSubtitle = 'Quick recharge';
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.coffee;
        break;
      case AttendanceStatus.working:
        statusText = 'Working';
        statusSubtitle = 'Shift in progress';
        statusColor = AppColors.success;
        statusIcon = LucideIcons.briefcase;
        break;
    }

    String timeSince = '';
    if (_currentLog?.statusStartTime != null) {
      final diff = DateTime.now().difference(_currentLog!.statusStartTime!);
      if (diff.inHours > 0) {
        timeSince = '${diff.inHours}h ${diff.inMinutes % 60}m';
      } else {
        timeSince = '${diff.inMinutes}m';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 32, color: statusColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Current Status",
                  style: ShadTheme.of(context).textTheme.muted.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: ShadTheme.of(context).textTheme.h3.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  statusSubtitle,
                  style: ShadTheme.of(context).textTheme.muted.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (timeSince.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SINCE",
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    timeSince,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary({Key? key}) {
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

  Widget _buildStatusCardSkeleton({Key? key}) {
    return Container(
          key: key,
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 140,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: Colors.grey.withAlpha(20));
  }

  Widget _buildTodaySummarySkeleton({Key? key}) {
    return Column(
          key: key,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 22,
              margin: const EdgeInsets.only(left: 4, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 80,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 60,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 2.seconds, color: Colors.grey.withAlpha(20));
  }
}
