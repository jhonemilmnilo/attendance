import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/models/overtime_request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/shadcn_ui.dart';

class OvertimeDialog extends StatefulWidget {
  final UserModel user;
  final OvertimeRequestModel? existingRequest;
  final VoidCallback onSaved;

  const OvertimeDialog({
    super.key,
    required this.user,
    this.existingRequest,
    required this.onSaved,
  });

  @override
  State<OvertimeDialog> createState() => _OvertimeDialogState();
}

class _OvertimeDialogState extends State<OvertimeDialog> {
  final ApiService _api = ApiService();
  final _reasonController = TextEditingController();

  late DateTime _requestDate;
  late TimeOfDay _schedTimeout;
  late TimeOfDay _otFrom;
  late TimeOfDay _otTo;
  int _durationMinutes = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _requestDate = widget.existingRequest!.requestDate;
      _schedTimeout = _parseTime(widget.existingRequest!.schedTimeout);
      _otFrom = _parseTime(widget.existingRequest!.otFrom);
      _otTo = _parseTime(widget.existingRequest!.otTo);
      _durationMinutes = widget.existingRequest!.durationMinutes;
      _reasonController.text = widget.existingRequest!.purpose;
    } else {
      _requestDate = DateTime.now();
      _schedTimeout = const TimeOfDay(hour: 17, minute: 0); // Default 5 PM
      _otFrom = _schedTimeout; // Default to sched_timeout
      _otTo = const TimeOfDay(hour: 18, minute: 0); // Default 1 hour later
      _reasonController.text = '';
      _calculateDuration();
      _loadTodayLog();
    }
  }

  Future<void> _loadTodayLog() async {
    final log = await _api.getTodayLog(widget.user.userId);
    if (log != null) {
      // In a real app, you might fetch the actual schedule.
      // For now, if there's a log, we can assume a standard timeout or fetch from department schedule.
      final schedule = await _api.getDepartmentSchedule(
        widget.user.departmentId,
      );
      if (schedule != null) {
        setState(() {
          _schedTimeout = schedule.workEnd;
          _otFrom = _schedTimeout;
          _calculateDuration();
        });
      }
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _calculateDuration() {
    final start = _otFrom.hour * 60 + _otFrom.minute;
    final end = _otTo.hour * 60 + _otTo.minute;

    int diff = end - start;
    if (diff < 0) diff = 0; // Negative OT not allowed

    setState(() {
      _durationMinutes = diff;
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_reasonController.text.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Error'),
          description: Text('Please provide a purpose for the overtime.'),
        ),
      );
      return;
    }

    if (_durationMinutes <= 0) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Error'),
          description: Text('OT end time must be after OT start time.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final request = OvertimeRequestModel(
      overtimeId: widget.existingRequest?.overtimeId,
      userId: widget.user.userId,
      departmentId: widget.user.departmentId,
      requestDate: _requestDate,
      schedTimeout:
          "${_schedTimeout.hour.toString().padLeft(2, '0')}:${_schedTimeout.minute.toString().padLeft(2, '0')}:00",
      otFrom:
          "${_otFrom.hour.toString().padLeft(2, '0')}:${_otFrom.minute.toString().padLeft(2, '0')}:00",
      otTo:
          "${_otTo.hour.toString().padLeft(2, '0')}:${_otTo.minute.toString().padLeft(2, '0')}:00",
      durationMinutes: _durationMinutes,
      purpose: _reasonController.text,
      status: widget.existingRequest?.status ?? OvertimeStatus.pending,
    );

    bool success;
    if (widget.existingRequest != null) {
      success = await _api.updateOvertimeRequest(request.overtimeId!, request);
    } else {
      success = await _api.createOvertimeRequest(request);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Overtime request saved successfully.'),
          ),
        );
      } else {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Error'),
            description: Text('Failed to save request. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: Text(
        widget.existingRequest != null
            ? 'Edit Overtime Request'
            : 'File Overtime Request',
      ),
      description: const Text(
        'Please provide the details for your overtime request.',
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildField(
              label: 'Request Date',
              child: ShadButton.outline(
                width: double.infinity,
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _requestDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setState(() => _requestDate = picked);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('MMM dd, yyyy').format(_requestDate)),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Scheduled Timeout',
              child: ShadButton.outline(
                width: double.infinity,
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _schedTimeout,
                  );
                  if (picked != null) {
                    setState(() {
                      _schedTimeout = picked;
                      _otFrom = picked; // Sync OT Start with Sched Timeout
                      _calculateDuration();
                    });
                  }
                },
                child: Text(_formatTime(_schedTimeout)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'OT Start Time',
                    child: ShadButton.outline(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _otFrom,
                        );
                        if (picked != null) {
                          setState(() {
                            _otFrom = picked;
                            _calculateDuration();
                          });
                        }
                      },
                      child: Text(_formatTime(_otFrom)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'OT End Time',
                    child: ShadButton.outline(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _otTo,
                        );
                        if (picked != null) {
                          setState(() {
                            _otTo = picked;
                            _calculateDuration();
                          });
                        }
                      },
                      child: Text(_formatTime(_otTo)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Total OT Duration:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${(_durationMinutes / 60).floor()}h ${_durationMinutes % 60}m',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Purpose',
              child: ShadInput(
                controller: _reasonController,
                placeholder: const Text(
                  'e.g., Working on month-end reports, Client presentation prep',
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      actions: [
        ShadButton.ghost(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Request'),
        ),
      ],
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period";
  }
}
