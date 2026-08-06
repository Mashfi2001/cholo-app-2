import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_panel.dart';
import 'backend_config.dart';
import 'driver_panel.dart';
import 'user_panel.dart';
import 'session.dart'; 
import 'driver_dashboard.dart';  



class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  final TextEditingController _resetOtpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showSignup = false;
  bool _showOtpVerification = false;
  bool _obscurePassword = true;
  String _otpEmail = '';
  String _errorMessage = '';
  String _selectedRole = 'PASSENGER'; // Default role
  final TextEditingController _otpController = TextEditingController();

  // Forgot password flow: 0 = off, 1 = enter email, 2 = enter OTP, 3 = new password
  int _forgotStep = 0;
  String _resetEmail = '';
  String _resetOtp = '';
  String _infoMessage = '';

  final Color brandOrange = const Color(0xFFF98825);
  final Color darkText = const Color(0xFF2C323A);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _resetEmailController.dispose();
    _resetOtpController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        final dynamic rawId = user['id'];
        final int userId =
            rawId is int ? rawId : int.parse(rawId.toString());

        // Start the session for this device. The backend keeps any sessions
        // this account holds on other devices alive alongside it.
        Session.start(
          id: userId,
          email: user['email'] ?? _emailController.text.trim(),
          sessionToken: data['token'] as String?,
          expiry: data['expiresAt'] != null
              ? DateTime.tryParse(data['expiresAt'])
              : null,
        );

        final String userName = user['name'] ?? 'User';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome $userName!')),
        );

        final String userRole = user['role'];

        if (userRole == 'ADMIN') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminPanel()),
          );
        } else if (userRole == 'DRIVER') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverDashboard(
                userId: userId,
                userName: userName,
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  UserPanel(userId: userId, userName: userName),
            ),
          );
        }
      } else if (response.statusCode == 403) {
        // Handle ban/suspension errors or OTP requirement
        final error = jsonDecode(response.body);
        
        if (error['requiresOtp'] == true) {
          setState(() {
            _showOtpVerification = true;
            _otpEmail = _emailController.text;
            _errorMessage = error['error'] ?? 'Please verify your email.';
          });
          return;
        }

        setState(() {
          _errorMessage = error['error'] ?? 'Login failed';
        });
        
        // Show a more prominent dialog for ban/suspension
        if (error['banned'] == true) {
          _showBanDialog(error['banType'] ?? 'temporary', error['suspendedUntil']);
        }
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
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
        title: Row(
          children: [
            Icon(
              banType == 'permanent' ? Icons.block : Icons.schedule,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                banType == 'permanent' ? 'Account Permanently Banned' : 'Account Temporarily Banned',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (banType == 'permanent')
              const Text(
                'Your account has been permanently banned. You cannot login to this application. If you believe this is a mistake, please contact support.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your account has been temporarily suspended.',
                  ),
                  const SizedBox(height: 12),
                  if (suspendedUntil != null)
                    Text(
                      'Banned until: ${DateTime.parse(suspendedUntil).toLocal().toString().split('.')[0]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can try logging in again after the suspension period ends.',
                  ),
                ],
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Understood',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'role': _selectedRole,
          'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['requiresOtp'] == true) {
          setState(() {
            _showOtpVerification = true;
            _otpEmail = _emailController.text;
            _showSignup = false;
            _errorMessage = '';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Signup successful! Please verify OTP.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful! Please login.')),
          );
          _nameController.clear();
          setState(() {
            _showSignup = false;
          });
        }
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'Signup failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _otpEmail,
          'otp': _otpController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully! You can now login.')),
        );
        setState(() {
          _showOtpVerification = false;
          _otpController.clear();
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'OTP Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/resend-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _otpEmail,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new OTP has been sent to your email.')),
        );
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'Failed to resend OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openForgotPassword() {
    setState(() {
      _forgotStep = 1;
      _errorMessage = '';
      _infoMessage = '';
      _resetEmail = _emailController.text.trim();
      _resetEmailController.text = _resetEmail;
      _resetOtp = '';
      _resetOtpController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    });
  }

  void _closeForgotPassword() {
    setState(() {
      _forgotStep = 0;
      _errorMessage = '';
      _infoMessage = '';
      _resetOtp = '';
      _resetOtpController.clear();
      _newPasswordController.clear();
      _confirmNewPasswordController.clear();
    });
  }

  // Step 1: ask the backend to email a reset OTP.
  Future<void> _sendResetOtp() async {
    final email = _resetEmailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _infoMessage = '';
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _resetEmail = email;
          _forgotStep = 2;
          _infoMessage = data['message'] ??
              'If an account exists for that email, we\'ve sent a password reset OTP to it.';
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'Failed to send reset OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Step 2: confirm the OTP before showing the new-password form.
  Future<void> _verifyResetOtp() async {
    final otp = _resetOtpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit OTP';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _infoMessage = '';
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/verify-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _resetEmail, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _resetOtp = otp;
          _forgotStep = 3;
          _infoMessage = 'OTP confirmed. Please choose a new password.';
        });
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'OTP verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Step 3: send the confirmed OTP together with the new password.
  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;

    if (newPassword.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long';
      });
      return;
    }

    if (newPassword != _confirmNewPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _errorMessage = '';
      _infoMessage = '';
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _resetEmail,
          'otp': _resetOtp,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ??
                'Password reset successfully. Please log in.'),
          ),
        );
        _emailController.text = _resetEmail;
        _passwordController.clear();
        _closeForgotPassword();
      } else {
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'Failed to reset password';
          // A rejected OTP means the confirmed code is no longer usable.
          if (response.statusCode == 400) {
            _forgotStep = 2;
            _resetOtp = '';
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Image.asset('assets/cholo_logo.png', height: 120),
              const SizedBox(height: 40),

              if (_forgotStep != 0)
                _buildForgotPasswordView()
              else ...[
              // Title
              if (!_showOtpVerification)
                Text(
                  _showSignup ? 'Create Account' : 'Login',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              if (!_showOtpVerification)
                const SizedBox(height: 24),

              if (_showOtpVerification)
                _buildOtpView(),

              // Name Field (only for signup)
              if (_showSignup && !_showOtpVerification)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: _nameController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: brandOrange,
                      ),
                      hintText: 'Full Name',
                      hintStyle: TextStyle(color: Colors.orange.shade300),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: brandOrange, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: brandOrange, width: 2.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              // Email/Username Field
              if (!_showOtpVerification)
                TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, color: brandOrange),
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.orange.shade300),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              if (!_showOtpVerification)
                const SizedBox(height: 16),

              // Password Field
              if (!_showOtpVerification)
                TextField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: brandOrange),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.orange.shade300,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.orange.shade300),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              if (!_showOtpVerification)
                const SizedBox(height: 16),

              // Confirm Password Field (only for signup)
              if (_showSignup && !_showOtpVerification)
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline, color: brandOrange),
                    hintText: 'Confirm Password',
                    hintStyle: TextStyle(color: Colors.orange.shade300),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              if (_showSignup && !_showOtpVerification)
                const SizedBox(height: 16),

              // Phone Field (only for signup)
              if (_showSignup && !_showOtpVerification)
                TextField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone_outlined, color: brandOrange),
                    hintText: 'Mobile Number',
                    hintStyle: TextStyle(color: Colors.orange.shade300),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: brandOrange, width: 2.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              if (_showSignup && !_showOtpVerification)
                const SizedBox(height: 16),

              // Role Selection (only for signup)
              if (_showSignup && !_showOtpVerification)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AbsorbPointer(
                    absorbing: _isLoading,
                    child: DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.admin_panel_settings,
                          color: brandOrange,
                        ),
                        hintText: 'Select Role',
                        hintStyle: TextStyle(color: Colors.orange.shade300),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: brandOrange,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: brandOrange,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'PASSENGER',
                          child: Text('Passenger'),
                        ),
                        DropdownMenuItem(
                          value: 'DRIVER',
                          child: Text('Driver'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                  ),
                ),

              // Error Message
              if (_errorMessage.isNotEmpty && !_showOtpVerification)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ),

              // Forgot Password Link (only for login)
              if (!_showSignup && !_showOtpVerification)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _openForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: darkText,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Action Button
              if (!_showOtpVerification)
                ElevatedButton(
                  onPressed: _isLoading ? null : (_showSignup ? _signup : _login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _showSignup ? 'Sign Up' : 'Login',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              const SizedBox(height: 32),

              // Toggle between Login and Signup
              if (!_showOtpVerification)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showSignup
                          ? 'Already have an account? '
                          : 'Not registered? ',
                      style: TextStyle(color: darkText, fontSize: 16),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _showSignup = !_showSignup;
                                _errorMessage = '';
                                _emailController.clear();
                                _passwordController.clear();
                                _confirmPasswordController.clear();
                                _nameController.clear();
                                _phoneController.clear();
                                _selectedRole = 'PASSENGER'; // Reset to default
                              });
                            },
                      child: Text(
                        _showSignup ? 'Login' : 'Sign Up',
                        style: TextStyle(
                          color: brandOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  InputDecoration _roundedDecoration({
    required IconData icon,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: brandOrange),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.orange.shade300),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: brandOrange, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: brandOrange, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildForgotPasswordView() {
    final String title = _forgotStep == 1
        ? 'Forgot Password'
        : _forgotStep == 2
            ? 'Enter OTP'
            : 'New Password';

    final String subtitle = _forgotStep == 1
        ? 'Enter the email address linked to your account and we will send you a 6-digit OTP.'
        : _forgotStep == 2
            ? 'Enter the 6-digit OTP sent to\n$_resetEmail'
            : 'Choose a new password for\n$_resetEmail';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 28),

        // Step 1: email entry
        if (_forgotStep == 1)
          TextField(
            controller: _resetEmailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: _roundedDecoration(
              icon: Icons.email_outlined,
              hint: 'Email',
            ),
          ),

        // Step 2: OTP entry
        if (_forgotStep == 2)
          TextField(
            controller: _resetOtpController,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '000000',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: brandOrange, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: brandOrange, width: 2.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              counterText: '',
            ),
          ),

        // Step 3: new password entry
        if (_forgotStep == 3) ...[
          TextField(
            controller: _newPasswordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            decoration: _roundedDecoration(
              icon: Icons.lock_outline,
              hint: 'New Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.orange.shade300,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmNewPasswordController,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            decoration: _roundedDecoration(
              icon: Icons.lock_outline,
              hint: 'Confirm New Password',
            ),
          ),
        ],

        const SizedBox(height: 20),

        if (_infoMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _infoMessage,
                style: TextStyle(color: darkText),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red.shade900),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        if (_forgotStep == 1) _primaryButton('Send OTP', _sendResetOtp),
        if (_forgotStep == 2) _primaryButton('Verify OTP', _verifyResetOtp),
        if (_forgotStep == 3) _primaryButton('Reset Password', _resetPassword),

        // Let the user request a fresh OTP if the first one expired or got lost.
        if (_forgotStep == 2)
          TextButton(
            onPressed: _isLoading ? null : _sendResetOtp,
            child: Text(
              'Resend OTP',
              style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold),
            ),
          ),

        TextButton(
          onPressed: _isLoading ? null : _closeForgotPassword,
          child: const Text(
            'Back to Login',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          'Email Verification',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Please enter the 6-digit OTP sent to\n$_otpEmail',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          enabled: !_isLoading,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '000000',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: brandOrange, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: brandOrange, width: 2.0),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            counterText: '',
          ),
        ),
        const SizedBox(height: 24),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red.shade900),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: brandOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Verify OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _resendOtp,
          child: Text(
            'Resend OTP',
            style: TextStyle(color: brandOrange, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _showOtpVerification = false;
                    _errorMessage = '';
                  });
                },
          child: const Text('Back to Login', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
