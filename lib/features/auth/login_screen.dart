import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' hide LucideIcons;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/shadcn_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') == true && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const _DummyDashboard()),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _api.login(
        _emailController.text,
        _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (user != null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.userId);
        await prefs.setInt('department_id', user.departmentId);
        await prefs.setString('user_name', user.fullName);
        await prefs.setBool('remember_me', _rememberMe);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const _DummyDashboard()),
        );
      } else if (mounted) {
        setState(() => _errorMessage = 'Invalid email or password');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred during login';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Mesh Background
          Positioned.fill(
            child:
                Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFAFAFA),
                            Color(0xFFF4F4F5),
                            Color(0xFFE4E4E7),
                            Color(0xFFD4D4D8),
                          ],
                        ),
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .shimmer(
                      duration: 5.seconds,
                      color: Colors.white.withOpacity(0.2),
                    ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo / Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.calendarCheck,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                      const SizedBox(height: 32),

                      // Title Section
                      Column(
                        children: [
                          Text(
                            "Welcome Back",
                            textAlign: TextAlign.center,
                            style: ShadTheme.of(context).textTheme.h2.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter your credentials to access your account",
                            textAlign: TextAlign.center,
                            style: ShadTheme.of(
                              context,
                            ).textTheme.muted.copyWith(fontSize: 15),
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                      const SizedBox(height: 40),

                      // Glassmorphic Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: glassDecoration(opacity: 0.8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.destructive.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.destructive
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          LucideIcons.alertCircle,
                                          size: 16,
                                          color: AppColors.destructive,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(
                                              color: AppColors.destructive,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().shake(),
                                  const SizedBox(height: 16),
                                ],
                                _buildEmailField(),
                                const SizedBox(height: 20),
                                _buildPasswordField(),
                                const SizedBox(height: 16),
                                ShadCheckbox(
                                  value: _rememberMe,
                                  onChanged: (val) =>
                                      setState(() => _rememberMe = val),
                                  label: Text(
                                    "Remember me",
                                    style: ShadTheme.of(
                                      context,
                                    ).textTheme.small,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildLoginButton(),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: ShadTheme.of(context).textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ShadInput(
          controller: _emailController,
          placeholder: const Text('m@example.com'),
          keyboardType: TextInputType.emailAddress,
          leading: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              LucideIcons.mail,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: ShadTheme.of(context).textTheme.small.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ShadInput(
          controller: _passwordController,
          placeholder: const Text('Enter your password'),
          obscureText: true,
          leading: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              LucideIcons.lock,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ShadButton(
        onPressed: _isLoading ? null : _handleLogin,
        leading: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(LucideIcons.logIn, size: 18),
        child: const Text(
          "Sign In",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}

class _DummyDashboard extends StatelessWidget {
  const _DummyDashboard();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Dashboard - Loading...")));
  }
}
