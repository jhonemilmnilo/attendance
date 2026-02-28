import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/attendance/approval_screen.dart';
import 'features/attendance/attendance_log_screen.dart';
import 'features/attendance/history_screen.dart';
import 'features/attendance/leave_screen.dart';
import 'features/attendance/overtime_screen.dart';
import 'features/attendance/undertime_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/payroll/employee_payroll_search_screen.dart';
import 'features/payroll/payroll_history_screen.dart';
import 'core/models/user_model.dart';
import 'core/services/api_service.dart';
import 'core/theme/shadcn_ui.dart';

void main() {
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: materialTheme,
      builder: (context, child) {
        return ShadTheme(data: shadTheme, child: child!);
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final userId = prefs.getInt('user_id');

    setState(() {
      _isLoggedIn = rememberMe && userId != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      return const MainShell();
    }

    return const LoginScreen();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  String _userName = '';
  int? _userId;
  int? _deptId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final deptId = prefs.getInt('department_id');
    final userName = prefs.getString('user_name') ?? 'User';

    if (mounted) {
      setState(() {
        _userId = userId;
        _deptId = deptId;
        _userName = userName;
      });
    }

    if (userId != null) {
      final api = ApiService();
      final user = await api.getUser(userId);
      if (mounted && user != null) {
        setState(() {
          _fullUser = user;
        });
      }
    }
  }

  UserModel? _fullUser;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                decoration: const BoxDecoration(color: AppColors.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_userId ?? "---"}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  children: [
                    _buildShadDrawerItem(
                      icon: LucideIcons.layoutDashboard,
                      label: 'Dashboard',
                      onTap: () {
                        _onTabSelected(0);
                        Navigator.pop(context);
                      },
                      selected: _currentIndex == 0,
                    ),
                    _buildShadDrawerItem(
                      icon: LucideIcons.timer,
                      label: 'Attendance Log',
                      onTap: () {
                        _onTabSelected(1);
                        Navigator.pop(context);
                      },
                      selected: _currentIndex == 1,
                    ),
                    _buildShadDrawerItem(
                      icon: LucideIcons.list,
                      label: 'Approvals',
                      onTap: () {
                        _onTabSelected(2);
                        Navigator.pop(context);
                      },
                      selected: _currentIndex == 2,
                    ),
                    _buildShadDrawerItem(
                      icon: LucideIcons.history,
                      label: 'History',
                      onTap: () {
                        _onTabSelected(3);
                        Navigator.pop(context);
                      },
                      selected: _currentIndex == 3,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: AppColors.border),
                    ),

                    Text(
                      "  PAYROLL & SERVICES",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedForeground.withOpacity(0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildShadDrawerItem(
                      icon: LucideIcons.search,
                      label: 'Employee Search',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EmployeePayrollSearchScreen(),
                          ),
                        );
                      },
                    ),
                    _buildShadDrawerItem(
                      icon: LucideIcons.banknote,
                      label: 'Payroll',
                      onTap: () {
                        Navigator.pop(context);
                        if (_fullUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PayrollHistoryScreen(user: _fullUser!),
                            ),
                          );
                        }
                      },
                    ),
                    _buildShadDrawerItem(
                      icon: LucideIcons.clock,
                      label: 'Undertime',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UndertimeScreen(userId: _userId ?? 0),
                          ),
                        );
                      },
                    ),
                    _buildShadDrawerItem(
                      icon: LucideIcons.zap,
                      label: 'Overtime',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OvertimeScreen(userId: _userId ?? 0),
                          ),
                        );
                      },
                    ),
                    _buildShadDrawerItem(
                      icon: LucideIcons.calendarDays,
                      label: 'Leave',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LeaveScreen(userId: _userId ?? 0),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Logout
              const Divider(color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: _handleLogout,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.logOut,
                          color: AppColors.destructive,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            color: AppColors.destructive,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: _getCurrentScreen(),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Attendance Log';
      case 2:
        return 'Approvals';
      case 3:
        return 'History';
      default:
        return 'Attendance';
    }
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          userId: _userId ?? 0,
          userName: _userName,
          onAction: _onTabSelected,
        );
      case 1:
        return AttendanceLogScreen(
          userId: _userId ?? 0,
          departmentId: _deptId ?? 0,
        );
      case 2:
        return ApprovalScreen(userId: _userId ?? 0);
      case 3:
        return HistoryScreen(userId: _userId ?? 0);
      default:
        return DashboardScreen(userId: _userId ?? 0, userName: _userName);
    }
  }

  Widget _buildShadDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppColors.primary.withOpacity(0.1))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.mutedForeground,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : AppColors.mutedForeground,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
