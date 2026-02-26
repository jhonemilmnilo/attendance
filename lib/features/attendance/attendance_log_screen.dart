import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/attendance_log_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';

class AttendanceLogScreen extends StatefulWidget {
  final int userId;
  final int departmentId;

  const AttendanceLogScreen({
    super.key,
    required this.userId,
    required this.departmentId,
  });

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  final ApiService _api = ApiService();
  AttendanceLogModel? _currentLog;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayLog();
  }

  Future<void> _fetchTodayLog() async {
    setState(() => _isLoading = true);
    final log = await _api.getTodayLog(widget.userId);
    if (mounted) {
      setState(() {
        _currentLog = log;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickTimeAndSubmit(String field) async {
    String? existingValue = _currentLog?.toJson()[field];
    String inputTime;
    if (existingValue != null && existingValue.isNotEmpty) {
      try {
        final rawValue = existingValue.replaceAll(RegExp(r'[Z+].*'), '');
        inputTime = DateFormat('HH:mm').format(DateTime.parse(rawValue));
      } catch (_) {
        inputTime = DateFormat('HH:mm').format(DateTime.now());
      }
    } else {
      inputTime = DateFormat('HH:mm').format(DateTime.now());
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Time (HH:mm)"),
        content: ShadInput(
          initialValue: inputTime,
          placeholder: const Text("18:53"),
          onChanged: (v) => inputTime = v,
          keyboardType: TextInputType.datetime,
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ShadButton(
            onPressed: () async {
              if (RegExp(r'^\d{2}:\d{2}$').hasMatch(inputTime)) {
                final parts = inputTime.split(':');
                final hour = int.parse(parts[0]);
                final minute = int.parse(parts[1]);
                final now = DateTime.now();
                final dateTime = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  hour,
                  minute,
                );

                Navigator.pop(context);
                await _submitAttendance(field, dateTime);
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAttendance(String field, DateTime dateTime) async {
    bool success = false;
    final now = DateTime.now();
    if (field == 'time_in') {
      success = await _api.createLog(
        userId: widget.userId,
        departmentId: widget.departmentId,
        date: now,
        timeIn: dateTime,
      );
    } else {
      if (_currentLog == null) {
        success = await _api.createLog(
          userId: widget.userId,
          departmentId: widget.departmentId,
          date: now,
          lunchStart: field == 'lunch_start' ? dateTime : null,
        );
      } else {
        success = await _api.updateLog(
          logId: _currentLog!.logId,
          lunchStart: field == 'lunch_start' ? dateTime : null,
          lunchEnd: field == 'lunch_end' ? dateTime : null,
          breakStart: field == 'break_start' ? dateTime : null,
          breakEnd: field == 'break_end' ? dateTime : null,
          timeOut: field == 'time_out' ? dateTime : null,
        );
      }
    }

    if (success) {
      _fetchTodayLog();
      _showSnackBar('Attendance updated successfully');
    } else {
      _showSnackBar('Failed to update attendance');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchTodayLog,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard().animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 32),
                _buildTimeEntriesCard()
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 32),
                _buildTimestampCard()
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_currentLog == null) {
      statusText = 'Not Clocked In';
      statusColor = AppColors.mutedForeground;
      statusIcon = LucideIcons.ghost;
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
      statusIcon = LucideIcons.activity;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    duration: 1.seconds,
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                  )
                  .fadeOut(),
              const SizedBox(width: 8),
              Text(
                "CURRENT STATUS",
                style: ShadTheme.of(context).textTheme.muted.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 32, color: statusColor),
          ),
          const SizedBox(height: 16),
          Text(
            statusText.toUpperCase(),
            style: ShadTheme.of(context).textTheme.h2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: ShadTheme.of(
              context,
            ).textTheme.muted.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEntriesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildTimeEntryRow("Time In", "time_in", LucideIcons.logIn),
          _buildDivider(),
          _buildTimeEntryRow(
            "Lunch Start",
            "lunch_start",
            LucideIcons.utensils,
          ),
          _buildDivider(),
          _buildTimeEntryRow("Lunch End", "lunch_end", LucideIcons.utensils),
          _buildDivider(),
          _buildTimeEntryRow("Break Start", "break_start", LucideIcons.coffee),
          _buildDivider(),
          _buildTimeEntryRow("Break End", "break_end", LucideIcons.coffee),
          _buildDivider(),
          _buildTimeEntryRow("Time Out", "time_out", LucideIcons.logOut),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: AppColors.border),
  );

  Widget _buildTimestampCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Audit Info",
            style: ShadTheme.of(
              context,
            ).textTheme.large.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimestampRow("System Created At", "created_at"),
              _buildDivider(),
              _buildTimestampRow("Last Updated At", "updated_at"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimestampRow(String label, String key) {
    String display = "Not set";
    Color textColor = AppColors.mutedForeground;

    if (_currentLog != null) {
      final formatted = key == 'created_at'
          ? _currentLog!.formattedCreatedAt
          : _currentLog!.formattedUpdatedAt;
      if (formatted != null) {
        display = formatted;
        textColor = AppColors.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _pickDateTimeAndSubmit(key, label),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    display,
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTimeAndSubmit(String field, String label) async {
    if (_currentLog == null) {
      _showSnackBar('Please create an attendance log first');
      return;
    }

    String? existingValue = _currentLog?.toJson()[field];
    String inputStr;
    if (existingValue != null && existingValue.isNotEmpty) {
      try {
        final rawValue = existingValue.replaceAll(RegExp(r'[Z+].*'), '');
        inputStr = DateFormat(
          'yyyy-MM-dd HH:mm',
        ).format(DateTime.parse(rawValue));
      } catch (_) {
        inputStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      }
    } else {
      inputStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $label"),
        content: ShadInput(
          initialValue: inputStr,
          placeholder: const Text("YYYY-MM-DD HH:mm"),
          onChanged: (v) => inputStr = v,
          keyboardType: TextInputType.datetime,
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ShadButton(
            onPressed: () async {
              try {
                final parts = inputStr.split(' ');
                final dateParts = parts[0].split('-');
                final timeParts = parts[1].split(':');
                final dateTime = DateTime(
                  int.parse(dateParts[0]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[2]),
                  int.parse(timeParts[0]),
                  int.parse(timeParts[1]),
                );

                Navigator.pop(context);
                bool success = await _api.updateLog(
                  logId: _currentLog!.logId,
                  createdAt: field == 'created_at' ? dateTime : null,
                  updatedAt: field == 'updated_at' ? dateTime : null,
                );

                if (success) {
                  _fetchTodayLog();
                  _showSnackBar('$label updated successfully');
                } else {
                  _showSnackBar('Failed to update ${label.toLowerCase()}');
                }
              } catch (_) {}
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEntryRow(String label, String key, IconData icon) {
    String? value = _currentLog?.toJson()[key];
    String display = "Set time";
    Color textColor = AppColors.mutedForeground;
    bool hasValue = false;
    DateTime? parsedDateTime;

    if (value != null && value.isNotEmpty) {
      try {
        final rawValue = value.replaceAll(RegExp(r'[Z+].*'), '');
        parsedDateTime = DateTime.parse(rawValue);
        display = DateFormat('h:mm a').format(parsedDateTime);
        textColor = AppColors.primary;
        hasValue = true;
      } catch (_) {
        display = value;
      }
    }

    return InkWell(
      onTap: () => _pickTimeAndSubmit(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: ShadTheme.of(
                    context,
                  ).textTheme.small.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  display,
                  style: ShadTheme.of(context).textTheme.small.copyWith(
                    color: textColor,
                    fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
