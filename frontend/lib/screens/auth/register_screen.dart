import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../backend_config.dart';
import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_input_field.dart';
import 'otp_verification_screen.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole selectedRole;

  const RegisterScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
          'role': widget.selectedRole == UserRole.driver ? 'DRIVER' : 'PASSENGER',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Navigate to OTP verification
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Registration failed. Please try again.';
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

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
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
                  // Back arrow
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.pureWhite,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Center(
                    child: Text(
                      'Create Account',
                      style: AppTextStyles.headingXL,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      widget.selectedRole == UserRole.driver
                          ? 'Join as a Driver'
                          : 'Join as a Passenger',
                      style: AppTextStyles.bodyM,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Form fields
                  CustomInputField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  // Phone number with prefix
                  CustomInputField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    prefix: Container(
                      margin: const EdgeInsets.only(left: 16, right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.borderGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+880',
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Create a password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  CustomInputField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    icon: Icons.lock_outline,
                    obscureText: true,
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
                  // Create Account button
                  CustomButton(
                    label: 'Create Account',
                    onPressed: _createAccount,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),
                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyM,
                      ),
                      GestureDetector(
                        onTap: _navigateToLogin,
                        child: Text(
                          'Sign In',
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
