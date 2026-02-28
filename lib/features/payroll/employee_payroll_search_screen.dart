import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart';

import '../../core/models/payroll_employee_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';
import 'payroll_history_screen.dart';

class EmployeePayrollSearchScreen extends StatefulWidget {
  const EmployeePayrollSearchScreen({super.key});

  @override
  State<EmployeePayrollSearchScreen> createState() =>
      _EmployeePayrollSearchScreenState();
}

class _EmployeePayrollSearchScreenState
    extends State<EmployeePayrollSearchScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<PayrollEmployeeModel> _allRecords = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _fetchAllRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllRecords() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getAllPayrollRecords();
      if (mounted) {
        setState(() {
          _allRecords = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Error'),
            description: Text('Failed to fetch payroll records: $e'),
          ),
        );
      }
    }
  }

  List<UserModel> _getEmployeesForTab(bool isDraft) {
    // Group by user ID to get unique employees
    final groupedByUserId = groupBy(_allRecords, (record) => record.userId);

    List<UserModel> employees = [];

    groupedByUserId.forEach((userId, records) {
      // Check if employee has records matching the status
      final hasMatchingStatus = records.any((r) {
        final rStatus = r.payrollRunStatus?.toUpperCase() ?? '';
        if (isDraft) {
          return rStatus == 'DRAFT';
        } else {
          return rStatus !=
              'DRAFT'; // Everything else is considered "Approved"/History
        }
      });

      if (hasMatchingStatus) {
        // Find the first record to extract user info
        final record = records.first;
        employees.add(
          UserModel(
            userId: record.userId,
            firstName: record.employeeName?.split(' ').first ?? 'Employee',
            lastName: record.employeeName?.split(' ').skip(1).join(' ') ?? '',
            email: '', // Not available in payroll record
            password: '',
            departmentId: 0,
            position: record.position,
          ),
        );
      }
    });

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      employees = employees
          .where(
            (e) =>
                e.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (e.position?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // Sort alphabetically
    employees.sort((a, b) => a.fullName.compareTo(b.fullName));

    return employees;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Employee Payroll Search'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ShadInput(
              controller: _searchController,
              placeholder: const Text('Search by employee name or position...'),
              leading: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppColors.mutedForeground,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              trailing: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Draft'),
              Tab(text: 'Approved'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedForeground,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),

          // Employee List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmployeeList(true),
                      _buildEmployeeList(false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(bool isDraft) {
    final employees = _getEmployeesForTab(isDraft);

    if (employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDraft ? LucideIcons.fileClock : LucideIcons.circleCheck,
              size: 64,
              color: AppColors.muted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No employees with ${isDraft ? 'draft' : 'approved'} payrolls'
                  : 'No results found for "$_searchQuery"',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 16),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: employees.length,
        itemBuilder: (context, index) {
          final employee = employees[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShadCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    employee.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  employee.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  employee.position ?? 'No Position',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () async {
                  // Fetch full user to get correct departmentId and other details
                  final fullUser = await _api.getUser(employee.userId);
                  if (context.mounted && fullUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PayrollHistoryScreen(user: fullUser),
                      ),
                    );
                  } else if (context.mounted) {
                    ShadToaster.of(context).show(
                      const ShadToast.destructive(
                        title: Text('Error'),
                        description: Text('Failed to fetch employee details'),
                      ),
                    );
                  }
                },
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05),
          );
        },
      ),
    );
  }
}
