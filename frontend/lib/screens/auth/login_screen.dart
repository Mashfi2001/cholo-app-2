import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../backend_config.dart';
import '../../session.dart';
import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_input_field.dart';
import '../../shells/admin_shell.dart';
import '../../shells/driver_shell.dart';
import '../../shells/passenger_shell.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailOrPhoneController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];
        final dynamic rawId = user['id'];
        final int userId = rawId is int ? rawId : int.parse(rawId.toString());
        Session.userId = userId;
        Session.userEmail = user['email'];
        final String userName = user['name'] ?? 'User';
        final String userRole = user['role'];

        // Show welcome snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Welcome back, $userName!',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.surfaceBlack,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate based on role
        if (userRole == 'ADMIN') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminShell()),
          );
        } else if (userRole == 'DRIVER') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverShell(
                userId: userId,
                userName: userName,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => PassengerShell(
                userId: userId,
                userName: userName,
              ),
            ),
          );
        }
      } else if (response.statusCode == 403) {
        // Handle ban/suspension
        final error = jsonDecode(response.body);
        _showBanDialog(error['banType'] ?? 'temporary', error['suspendedUntil']);
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Login failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please check your internet.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBanDialog(String banType, String? suspendedUntil) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderGray),
        ),
        title: Row(
          children: [
            Icon(
              banType == 'permanent' ? Icons.block : Icons.schedule,
              color: AppColors.dangerRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                banType == 'permanent'
                    ? 'Account Permanently Banned'
                    : 'Account Temporarily Banned',
                style: AppTextStyles.headingM,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banType == 'permanent')
              Text(
                'Your account has been permanently banned. You cannot login to this application. If you believe this is a mistake, please contact support.',
                style: AppTextStyles.bodyM,
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account has been temporarily suspended.',
                    style: AppTextStyles.bodyM,
                  ),
                  const SizedBox(height: 12),
                  if (suspendedUntil != null)
                    Text(
                      'Banned until: ${DateTime.parse(suspendedUntil).toLocal().toString().split('.')[0]}',
                      style: AppTextStyles.bodyL.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningAmber,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'You can try logging in again after the suspension period ends.',
                    style: AppTextStyles.bodyM,
                  ),
                ],
              ),
          ],
        ),
        actions: [
          CustomButton(
            label: 'Understood',
            variant: CustomButtonVariant.danger,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Back arrow (for consistency, though this is entry point)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.pureWhite,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Center(
                    child: Text(
                      'Welcome Back',
                      style: AppTextStyles.headingXL,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sign in to continue',
                      style: AppTextStyles.bodyM,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Form fields
                  CustomInputField(
                    controller: _emailOrPhoneController,
                    label: 'Phone or Email',
                    hint: 'Enter your phone or email',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to forgot password
                      },
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.labelBold.copyWith(
                          color: AppColors.silverMid,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.dangerRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.dangerRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTextStyles.bodyM.copyWith(
                                color: AppColors.dangerRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Sign In button
                  CustomButton(
                    label: 'Sign In',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  // Don't have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodyM,
                      ),
                      GestureDetector(
                        onTap: _navigateToRegister,
                        child: Text(
                          'Register',
                          style: AppTextStyles.labelBold.copyWith(
                            color: AppColors.pureWhite,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
