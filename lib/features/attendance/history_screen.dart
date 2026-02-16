import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart' hide LucideIcons;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/attendance_log_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';

class HistoryScreen extends StatefulWidget {
  final int userId;

  const HistoryScreen({super.key, required this.userId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _api = ApiService();
  final ScrollController _scrollController = ScrollController();
  List<AttendanceLogModel> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _logs = [];
    });

    final logs = await _api.getHistory(widget.userId, page: _currentPage);
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
        if (logs.length < 10) _hasMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    final logs = await _api.getHistory(widget.userId, page: _currentPage);
    if (mounted) {
      setState(() {
        _logs.addAll(logs);
        _isLoadingMore = false;
        if (logs.length < 10) _hasMore = false;
      });
    }
  }

  void _showEditDialog(AttendanceLogModel log) {
    showDialog(
      context: context,
      builder: (context) => EditLogDialog(
        log: log,
        onSave: () {
          _fetchHistory(); // Refresh list after edit
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_logs.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.muted.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.history,
                  size: 48,
                  color: AppColors.mutedForeground,
                ),
              ).animate().scale(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                "No History Found",
                style: ShadTheme.of(
                  context,
                ).textTheme.h3.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                "You haven't logged any attendance yet.",
                style: ShadTheme.of(context).textTheme.muted,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchHistory,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  "Attendance History",
                  style: ShadTheme.of(context).textTheme.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _logs.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _logs.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistoryCard(log)
                          .animate()
                          .fadeIn(delay: (index % 10 * 50).ms, duration: 400.ms)
                          .slideX(begin: 0.1, delay: (index % 10 * 50).ms),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(AttendanceLogModel log) {
    final status = log.currentStatus;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showEditDialog(log),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.calendarDays,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.shortDate,
                      style: ShadTheme.of(context).textTheme.small.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${log.formattedTimeIn ?? '--:--'} - ${log.formattedTimeOut ?? '--:--'}",
                      style: ShadTheme.of(context).textTheme.muted.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AttendanceStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case AttendanceStatus.working:
        color = AppColors.success;
        icon = LucideIcons.checkCircle;
        break;
      case AttendanceStatus.clockedOut:
        color = AppColors.primary;
        icon = LucideIcons.circle;
        break;
      case AttendanceStatus.onLunch:
      case AttendanceStatus.onBreak:
        color = AppColors.warning;
        icon = LucideIcons.timer;
        break;
      default:
        color = AppColors.mutedForeground;
        icon = LucideIcons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            status.displayText.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class EditLogDialog extends StatefulWidget {
  final AttendanceLogModel log;
  final VoidCallback onSave;

  const EditLogDialog({super.key, required this.log, required this.onSave});

  @override
  State<EditLogDialog> createState() => _EditLogDialogState();
}

class _EditLogDialogState extends State<EditLogDialog> {
  final ApiService _api = ApiService();
  late Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _formData = Map.from(widget.log.toJson());
  }

  Future<void> _pickTime(String field) async {
    final initialStr = _formData[field];
    final DateTime initialDate =
        (initialStr != null && initialStr.toString().isNotEmpty)
        ? DateTime.parse(initialStr)
        : DateTime.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (picked != null && mounted) {
      final datePart = DateTime.parse(widget.log.logDate);
      final newDateTime = DateTime(
        datePart.year,
        datePart.month,
        datePart.day,
        picked.hour,
        picked.minute,
      );

      setState(() {
        _formData[field] = newDateTime.toIso8601String();
      });

      await _api.updateLog(
        logId: widget.log.logId,
        timeIn: field == 'time_in' ? newDateTime : null,
        lunchStart: field == 'lunch_start' ? newDateTime : null,
        lunchEnd: field == 'lunch_end' ? newDateTime : null,
        breakStart: field == 'break_start' ? newDateTime : null,
        breakEnd: field == 'break_end' ? newDateTime : null,
        timeOut: field == 'time_out' ? newDateTime : null,
      );
    }
  }

  Widget _buildField(String label, String key, IconData icon) {
    final value = _formData[key];
    String display = "Not set";
    bool hasValue = false;
    if (value != null && value.toString().isNotEmpty) {
      try {
        display = DateFormat('h:mm a').format(DateTime.parse(value));
        hasValue = true;
      } catch (_) {}
    }

    return InkWell(
      onTap: () => _pickTime(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mutedForeground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              display,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: hasValue ? AppColors.primary : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Edit Attendance", style: ShadTheme.of(context).textTheme.h4),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField("Time In", "time_in", LucideIcons.logIn),
            const Divider(),
            _buildField("Lunch Start", "lunch_start", LucideIcons.utensils),
            _buildField("Lunch End", "lunch_end", LucideIcons.utensils),
            const Divider(),
            _buildField("Break Start", "break_start", LucideIcons.coffee),
            _buildField("Break End", "break_end", LucideIcons.coffee),
            const Divider(),
            _buildField("Time Out", "time_out", LucideIcons.logOut),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ShadButton(
          onPressed: () {
            widget.onSave();
          },
          child: const Text("Save Changes"),
        ),
      ],
    );
  }
}
