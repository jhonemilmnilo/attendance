import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/models/undertime_request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/shadcn_ui.dart';

class UndertimeDialog extends StatefulWidget {
  final UserModel user;
  final UndertimeRequestModel? existingRequest;
  final VoidCallback onSaved;

  const UndertimeDialog({
    super.key,
    required this.user,
    this.existingRequest,
    required this.onSaved,
  });

  @override
  State<UndertimeDialog> createState() => _UndertimeDialogState();
}

class _UndertimeDialogState extends State<UndertimeDialog> {
  final _api = ApiService();
  final _reasonController = TextEditingController();

  DateTime _requestDate = DateTime.now();
  TimeOfDay _schedTimeout = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _actualTimeout = const TimeOfDay(hour: 16, minute: 0);
  int _durationMinutes = 60;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      final req = widget.existingRequest!;
      _requestDate = req.requestDate;
      _reasonController.text = req.reason;
      _durationMinutes = req.durationMinutes;

      final schedParts = req.schedTimeout.split(':');
      _schedTimeout = TimeOfDay(
        hour: int.parse(schedParts[0]),
        minute: int.parse(schedParts[1]),
      );

      final actualParts = req.actualTimeout.split(':');
      _actualTimeout = TimeOfDay(
        hour: int.parse(actualParts[0]),
        minute: int.parse(actualParts[1]),
      );
    }
    _calculateDuration();
  }

  void _calculateDuration() {
    final now = DateTime.now();
    final sched = DateTime(
      now.year,
      now.month,
      now.day,
      _schedTimeout.hour,
      _schedTimeout.minute,
    );
    var actual = DateTime(
      now.year,
      now.month,
      now.day,
      _actualTimeout.hour,
      _actualTimeout.minute,
    );

    // If actual is after sched, it's not undertime (maybe it's next day or just user error)
    // But for undertime, actual should be before sched.
    final diff = sched.difference(actual).inMinutes;
    setState(() {
      _durationMinutes = diff > 0 ? diff : 0;
    });
  }

  Future<void> _handleSave() async {
    if (_reasonController.text.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Please provide a reason.'),
        ),
      );
      return;
    }

    if (_durationMinutes <= 0) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Actual timeout must be before scheduled timeout.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final request = UndertimeRequestModel(
      undertimeId: widget.existingRequest?.undertimeId,
      userId: widget.user.userId,
      departmentId: widget.user.departmentId,
      requestDate: _requestDate,
      schedTimeout:
          "${_schedTimeout.hour.toString().padLeft(2, '0')}:${_schedTimeout.minute.toString().padLeft(2, '0')}:00",
      actualTimeout:
          "${_actualTimeout.hour.toString().padLeft(2, '0')}:${_actualTimeout.minute.toString().padLeft(2, '0')}:00",
      durationMinutes: _durationMinutes,
      reason: _reasonController.text,
      status: widget.existingRequest?.status ?? UndertimeStatus.pending,
    );

    bool success;
    if (widget.existingRequest != null) {
      success = await _api.updateUndertimeRequest(
        request.undertimeId!,
        request,
      );
    } else {
      success = await _api.createUndertimeRequest(request);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Undertime request saved successfully.'),
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
            ? 'Edit Undertime Request'
            : 'File Undertime Request',
      ),
      description: const Text(
        'Please provide the details for your undertime request.',
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
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Scheduled Timeout',
                    child: ShadButton.outline(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _schedTimeout,
                        );
                        if (picked != null) {
                          setState(() => _schedTimeout = picked);
                          _calculateDuration();
                        }
                      },
                      child: Text(_formatTime(_schedTimeout)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'Actual Timeout',
                    child: ShadButton.outline(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _actualTimeout,
                        );
                        if (picked != null) {
                          setState(() => _actualTimeout = picked);
                          _calculateDuration();
                        }
                      },
                      child: Text(_formatTime(_actualTimeout)),
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
                    'Duration:',
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
              label: 'Reason',
              child: ShadInput(
                controller: _reasonController,
                placeholder: const Text(
                  'e.g., Medical appointment, Family emergency',
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
