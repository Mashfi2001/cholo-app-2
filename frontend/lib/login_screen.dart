import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'admin_panel.dart';
import 'backend_config.dart';
import 'driver_panel.dart';
import 'user_panel.dart';
import 'session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _showSignup = false;
  String _errorMessage = '';
  String _selectedRole = 'PASSENGER';

  final Color brandOrange = const Color(0xFFF98825);
  final Color darkText = const Color(0xFF2C323A);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];
        final dynamic rawId = user['id'];
        final int userId =
            rawId is int ? rawId : int.parse(rawId.toString());
        Session.userId = userId;
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
              builder: (context) =>
                  DriverPanel(userId: userId, userName: userName),
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
        // Handle ban/suspension errors
        final error = jsonDecode(response.body);
        setState(() {
          _errorMessage = error['error'] ?? 'Login failed';
        });
        
        // Show a more prominent dialog for ban/suspension
        if (error['banned'] == true) {
          _showBanDialog(error['banType'] ?? 'temporary', error['suspendedUntil']);
        }
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Login failed';
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
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful! Please login.')),
        );

        setState(() {
          _showSignup = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/cholo_logo.png', height: 120),
              const SizedBox(height: 30),

              Text(
                _showSignup ? "Create Account" : "Login",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),

              const SizedBox(height: 20),

              if (_showSignup)
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 10),

              if (_showSignup)
                DropdownButton<String>(
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'PASSENGER',
                      child: Text('Passenger'),
                    ),
                    DropdownMenuItem(value: 'DRIVER', child: Text('Driver')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),

              const SizedBox(height: 20),

              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : (_showSignup ? _signup : _login),
                child: Text(_showSignup ? "Signup" : "Login"),
              ),

              TextButton(
                onPressed: () {
                  setState(() {
                    _showSignup = !_showSignup;
                  });
                },
                child: Text(
                  _showSignup
                      ? "Already have account? Login"
                      : "Create account",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
