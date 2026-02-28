import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/leave_request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/shadcn_ui.dart';
import 'widgets/leave_dialog.dart';

class LeaveScreen extends StatefulWidget {
  final int userId;

  const LeaveScreen({super.key, required this.userId});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final ApiService _api = ApiService();
  UserModel? _user;
  List<LeaveRequestModel> _allRequests = [];
  bool _isLoading = true;
  bool _showTodayOnly = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _api.getUser(widget.userId);
      final requests = await _api.getLeaveRequests(widget.userId);
      setState(() {
        _user = user;
        _allRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Error'),
          description: Text('Failed to load leave requests.'),
        ),
      );
    }
  }

  List<LeaveRequestModel> get _filteredRequests {
    if (!_showTodayOnly) return _allRequests;
    final now = DateTime.now();
    return _allRequests.where((r) {
      return r.filedAt?.year == now.year &&
          r.filedAt?.month == now.month &&
          r.filedAt?.day == now.day;
    }).toList();
  }

  void _showFileDialog([LeaveRequestModel? request]) {
    if (_user == null) return;
    showDialog(
      context: context,
      builder: (context) => LeaveDialog(
        user: _user!,
        existingRequest: request,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _handleDelete(int leaveId) async {
    final success = await _api.deleteLeaveRequest(leaveId);
    if (success) {
      _loadData();
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Request deleted successfully.')),
      );
    } else {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Error'),
          description: Text('Failed to delete request.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Leave Requests'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showTodayOnly ? LucideIcons.calendar : LucideIcons.history,
              color: AppColors.primary,
            ),
            onPressed: () => setState(() => _showTodayOnly = !_showTodayOnly),
            tooltip: _showTodayOnly ? 'Show All History' : 'Show Today Only',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredRequests.isEmpty
          ? _buildEmptyState()
          : _buildRequestList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFileDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.plane,
            size: 64,
            color: AppColors.mutedForeground.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showTodayOnly
                ? 'No leave requests filed today'
                : 'No leave requests found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          if (_showTodayOnly && _allRequests.isNotEmpty)
            ShadButton.ghost(
              onPressed: () => setState(() => _showTodayOnly = false),
              child: const Text('View All History'),
            ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildRequestList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredRequests.length,
        itemBuilder: (context, index) {
          final item = _filteredRequests[index];
          return _buildRequestCard(
            item,
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  Widget _buildRequestCard(LeaveRequestModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.leaveType.label.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(item.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoItem(
                        'From',
                        DateFormat('MMM dd').format(item.leaveStart),
                        LucideIcons.calendar,
                      ),
                      const SizedBox(width: 24),
                      _buildInfoItem(
                        'To',
                        DateFormat('MMM dd').format(item.leaveEnd),
                        LucideIcons.calendar,
                      ),
                      const SizedBox(width: 24),
                      _buildInfoItem(
                        'Total',
                        item.formattedTotalDays,
                        LucideIcons.clock,
                      ),
                    ],
                  ),
                  if (item.reason != null && item.reason!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Reason:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.reason!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.status == LeaveStatus.pending &&
                item.filedAt != null &&
                item.filedAt!.year == DateTime.now().year &&
                item.filedAt!.month == DateTime.now().month &&
                item.filedAt!.day == DateTime.now().day) ...[
              const Divider(height: 1, color: AppColors.border),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.ghost(
                      onPressed: () => _showFileDialog(item),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.pencil, size: 14),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, height: 24, color: AppColors.border),
                  Expanded(
                    child: ShadButton.ghost(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ShadDialog(
                            title: const Text('Delete Leave Request'),
                            description: const Text(
                              'Are you sure you want to delete this leave request? This action cannot be undone.',
                            ),
                            actions: [
                              ShadButton.ghost(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ShadButton.destructive(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleDelete(item.leaveId!);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.trash,
                            size: 14,
                            color: AppColors.destructive,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.destructive),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LeaveStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}
