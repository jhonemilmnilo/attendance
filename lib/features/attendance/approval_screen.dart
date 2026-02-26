import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/approval_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';

class ApprovalScreen extends StatefulWidget {
  final int userId;

  const ApprovalScreen({super.key, required this.userId});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final ApiService _api = ApiService();
  List<ApprovalModel> _approvals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    final data = await _api.getApprovals(widget.userId);
    if (mounted) {
      setState(() {
        _approvals = data;
        _isLoading = false;
      });
    }
  }

  void _showEditDialog(ApprovalModel item) {
    showDialog(
      context: context,
      builder: (context) => EditApprovalDialog(
        data: item,
        onSave: () {
          _fetchApprovals();
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

    if (_approvals.isEmpty) {
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
                  LucideIcons.fileText,
                  size: 48,
                  color: AppColors.mutedForeground,
                ),
              ).animate().scale(duration: 400.ms),
              const SizedBox(height: 24),
              Text(
                "No Pending Approvals",
                style: ShadTheme.of(
                  context,
                ).textTheme.h3.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                "All set! No approvals are waiting for you.",
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
          onRefresh: _fetchApprovals,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  "Approvals",
                  style: ShadTheme.of(context).textTheme.h2.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _approvals.length,
                  itemBuilder: (context, index) {
                    final item = _approvals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildApprovalCard(item)
                          .animate()
                          .fadeIn(delay: (index * 50).ms, duration: 400.ms)
                          .slideY(begin: 0.1, delay: (index * 50).ms),
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

  Widget _buildApprovalCard(ApprovalModel item) {
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
        onTap: () => _showEditDialog(item),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.shortDate,
                        style: ShadTheme.of(context).textTheme.small.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(
                      LucideIcons.briefcase,
                      "Work",
                      item.formattedWorkHours,
                    ),
                    _buildDivider(),
                    _buildMetric(LucideIcons.zap, "OT", item.formattedOvertime),
                    _buildDivider(),
                    _buildMetric(
                      LucideIcons.clock,
                      "Late",
                      "${item.lateMinutes}m",
                    ),
                  ],
                ),
              ),
              if (item.remarks != null && item.remarks!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.messageSquare,
                      size: 14,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.remarks!,
                        style: ShadTheme.of(context).textTheme.small.copyWith(
                          color: AppColors.mutedForeground,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Container(height: 24, width: 1, color: AppColors.border);

  Widget _buildMetric(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.success;
        icon = LucideIcons.circleCheck;
        break;
      case 'rejected':
        color = AppColors.destructive;
        icon = LucideIcons.circleX;
        break;
      default:
        color = AppColors.warning;
        icon = LucideIcons.circle;
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
            status.toUpperCase(),
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

class EditApprovalDialog extends StatefulWidget {
  final ApprovalModel data;
  final VoidCallback onSave;

  const EditApprovalDialog({
    super.key,
    required this.data,
    required this.onSave,
  });

  @override
  State<EditApprovalDialog> createState() => _EditApprovalDialogState();
}

class _EditApprovalDialogState extends State<EditApprovalDialog> {
  final ApiService _api = ApiService();
  late TextEditingController _workController;
  late TextEditingController _lateController;
  late TextEditingController _undertimeController;
  late TextEditingController _overtimeController;
  late TextEditingController _remarksController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _workController = TextEditingController(
      text: widget.data.workMinutes.toString(),
    );
    _lateController = TextEditingController(
      text: widget.data.lateMinutes.toString(),
    );
    _undertimeController = TextEditingController(
      text: widget.data.undertimeMinutes.toString(),
    );
    _overtimeController = TextEditingController(
      text: widget.data.overtimeMinutes.toString(),
    );
    _remarksController = TextEditingController(text: widget.data.remarks ?? '');
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final updateData = {
      "work_minutes": int.tryParse(_workController.text) ?? 0,
      "late_minutes": int.tryParse(_lateController.text) ?? 0,
      "undertime_minutes": int.tryParse(_undertimeController.text) ?? 0,
      "overtime_minutes": int.tryParse(_overtimeController.text) ?? 0,
      "remarks": _remarksController.text,
    };

    final success = await _api.updateApproval(
      widget.data.approvalId,
      updateData,
    );
    setState(() => _isSaving = false);

    if (success) {
      widget.onSave();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Update Approval", style: ShadTheme.of(context).textTheme.h4),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput("Work Minutes", _workController, LucideIcons.briefcase),
            const SizedBox(height: 12),
            _buildInput("Late Minutes", _lateController, LucideIcons.clock),
            const SizedBox(height: 12),
            _buildInput(
              "Overtime Minutes",
              _overtimeController,
              LucideIcons.zap,
            ),
            const SizedBox(height: 12),
            _buildInput(
              "Remarks",
              _remarksController,
              LucideIcons.messageSquare,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ShadButton(
          onPressed: _isSaving ? null : _save,
          leading: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          child: const Text("Update"),
        ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return ShadInput(
      controller: controller,
      placeholder: Text(label),
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, size: 16, color: AppColors.mutedForeground),
      ),
      keyboardType: maxLines > 1
          ? TextInputType.multiline
          : TextInputType.number,
    );
  }
}
