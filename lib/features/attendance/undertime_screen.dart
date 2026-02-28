import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:lucide_icons/lucide_icons.dart'; // Conflict with shadcn_ui

import '../../../core/models/undertime_request_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/shadcn_ui.dart';
import 'widgets/undertime_dialog.dart';

class UndertimeScreen extends StatefulWidget {
  final int userId;

  const UndertimeScreen({super.key, required this.userId});

  @override
  State<UndertimeScreen> createState() => _UndertimeScreenState();
}

class _UndertimeScreenState extends State<UndertimeScreen> {
  final _api = ApiService();
  UserModel? _user;
  List<UndertimeRequestModel> _allRequests = [];
  bool _isLoading = true;
  bool _showOnlyToday = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _api.getUser(widget.userId);
    final requests = await _api.getUndertimeRequests(widget.userId);

    if (mounted) {
      setState(() {
        _user = user;
        _allRequests = requests;
        _isLoading = false;
      });
    }
  }

  List<UndertimeRequestModel> get _filteredRequests {
    if (!_showOnlyToday) return _allRequests;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _allRequests
        .where(
          (r) => DateFormat('yyyy-MM-dd').format(r.requestDate) == todayStr,
        )
        .toList();
  }

  void _showFileDialog([UndertimeRequestModel? existing]) {
    if (_user == null) return;
    showDialog(
      context: context,
      builder: (context) => UndertimeDialog(
        user: _user!,
        existingRequest: existing,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _handleDelete(int id) async {
    final success = await _api.deleteUndertimeRequest(id);
    if (success) {
      _loadData();
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(description: Text('Request deleted successfully.')),
        );
      }
    } else {
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            description: Text('Failed to delete request.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
        title: const Text('Undertime Requests'),
        actions: [
          IconButton(
            icon: Icon(_showOnlyToday ? Icons.calendar_today : Icons.history),
            onPressed: () => setState(() => _showOnlyToday = !_showOnlyToday),
            tooltip: _showOnlyToday ? 'Show All History' : 'Show Only Today',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _filteredRequests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredRequests.length,
                      itemBuilder: (context, index) {
                        final item = _filteredRequests[index];
                        return _buildRequestCard(item)
                            .animate()
                            .fadeIn(delay: (index * 50).ms)
                            .slideY(begin: 0.1);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFileDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              LucideIcons.clock,
              size: 48,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showOnlyToday ? "No Requests Today" : "No Requests Found",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _showOnlyToday
                ? "You haven't filed any undertime for today."
                : "You haven't filed any undertime requests yet.",
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
          if (_showOnlyToday && _allRequests.isNotEmpty)
            ShadButton.ghost(
              onPressed: () => setState(() => _showOnlyToday = false),
              child: const Text("View All History"),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(UndertimeRequestModel item) {
    Color statusColor;
    switch (item.status) {
      case UndertimeStatus.approved:
        statusColor = AppColors.success;
        break;
      case UndertimeStatus.rejected:
        statusColor = AppColors.destructive;
        break;
      case UndertimeStatus.cancelled:
        statusColor = AppColors.mutedForeground;
        break;
      case UndertimeStatus.pending:
        statusColor = AppColors.warning;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.status.name.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      item.formattedRequestDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      'Scheduled',
                      item.formattedSchedTimeout,
                      LucideIcons.calendar,
                    ),
                    const SizedBox(width: 24),
                    _buildInfoItem(
                      'Request Exit',
                      item.formattedActualTimeout,
                      LucideIcons.logOut,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          Text(
                            '${(item.durationMinutes / 60).floor()}h ${item.durationMinutes % 60}m',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'REASON',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mutedForeground,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (item.status == UndertimeStatus.pending &&
              item.requestDate.year == DateTime.now().year &&
              item.requestDate.month == DateTime.now().month &&
              item.requestDate.day == DateTime.now().day) ...[
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
                          title: const Text('Delete Request'),
                          description: const Text(
                            'Are you sure you want to delete this undertime request? This action cannot be undone.',
                          ),
                          actions: [
                            ShadButton.ghost(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ShadButton.destructive(
                              onPressed: () {
                                Navigator.pop(context);
                                _handleDelete(item.undertimeId!);
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
