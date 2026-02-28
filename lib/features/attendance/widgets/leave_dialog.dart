import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/models/leave_request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/shadcn_ui.dart';

class LeaveDialog extends StatefulWidget {
  final UserModel user;
  final LeaveRequestModel? existingRequest;
  final VoidCallback onSaved;

  const LeaveDialog({
    super.key,
    required this.user,
    this.existingRequest,
    required this.onSaved,
  });

  @override
  State<LeaveDialog> createState() => _LeaveDialogState();
}

class _LeaveDialogState extends State<LeaveDialog> {
  final ApiService _api = ApiService();
  final _reasonController = TextEditingController();
  final _daysController = TextEditingController();

  LeaveType _leaveType = LeaveType.vacation;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _leaveType = widget.existingRequest!.leaveType;
      _startDate = widget.existingRequest!.leaveStart;
      _endDate = widget.existingRequest!.leaveEnd;
      _daysController.text = widget.existingRequest!.totalDays.toString();
      _reasonController.text = widget.existingRequest!.reason ?? '';
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
      _daysController.text = '1.0';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final double? totalDays = double.tryParse(_daysController.text);
    if (totalDays == null || totalDays <= 0) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Error'),
          description: Text('Please enter a valid number of days.'),
        ),
      );
      return;
    }

    if (_reasonController.text.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Error'),
          description: Text('Please provide a reason for the leave.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final request = LeaveRequestModel(
      leaveId: widget.existingRequest?.leaveId,
      userId: widget.user.userId,
      departmentId: widget.user.departmentId,
      leaveType: _leaveType,
      leaveStart: _startDate,
      leaveEnd: _endDate,
      totalDays: totalDays,
      reason: _reasonController.text,
      status: widget.existingRequest?.status ?? LeaveStatus.pending,
    );

    bool success;
    if (widget.existingRequest != null) {
      success = await _api.updateLeaveRequest(request.leaveId!, request);
    } else {
      success = await _api.createLeaveRequest(request);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSaved();
        Navigator.pop(context);
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text('Leave request saved successfully.'),
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
            ? 'Edit Leave Request'
            : 'File Leave Request',
      ),
      description: const Text(
        'Please provide the details for your leave request.',
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildField(
              label: 'Leave Type',
              child: ShadSelect<LeaveType>(
                placeholder: const Text('Select leave type'),
                initialValue: _leaveType,
                options: LeaveType.values
                    .map(
                      (type) =>
                          ShadOption(value: type, child: Text(type.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _leaveType = v!),
                selectedOptionBuilder: (context, value) => Text(value.label),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'Start Date',
                    child: ShadButton.outline(
                      width: double.infinity,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: Text(DateFormat('MMM dd').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    label: 'End Date',
                    child: ShadButton.outline(
                      width: double.infinity,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: Text(DateFormat('MMM dd').format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Total Days',
              child: ShadInput(
                controller: _daysController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                placeholder: const Text('e.g., 1.0 or 1.5'),
              ),
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Reason',
              child: ShadInput(
                controller: _reasonController,
                placeholder: const Text('Provide a reason for the leave...'),
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
}
