import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isLoading = true;
  Map<String, dynamic>? fullUserData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userId = widget.user['id'];
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }
      
      final response = await http.get(Uri.parse('$backendUrl/api/auth/$userId'));
      if (response.statusCode == 200) {
        setState(() {
          fullUserData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color brandOrange = const Color(0xFFF98825);
    final Color darkText = const Color(0xFF2C323A);
    
    final displayData = fullUserData ?? widget.user;
    final String name = displayData['name'] ?? 'Unknown';
    final String role = displayData['role'] ?? 'Unknown role';
    final String email = displayData['email'] ?? widget.user['email'] ?? 'Not available';
    final String id = displayData['id']?.toString() ?? widget.user['id']?.toString() ?? 'Not available';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: brandOrange.withOpacity(0.16),
                      child: Text(
                        _initials(name),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: brandOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoTile('Email', email),
                    const SizedBox(height: 12),
                    _buildInfoTile('Phone', displayData['phone']?.toString() ?? 'Not available'),
                    const SizedBox(height: 12),
                    _buildInfoTile('Role', role),
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      'User ID',
                      id,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This profile screens shows the selected user’s public data. For driver details, you can extend this view when more driver-specific fields become available.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _initials(dynamic name) {
    if (name is String && name.trim().isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
      return '${parts.first[0].toUpperCase()}${parts.last[0].toUpperCase()}';
    }
    return '?';
  }

  Widget _buildInfoTile(String label, String value) {
    // If value is empty or —, show "Not available" instead
    final displayValue = (value.isEmpty || value == '—') ? 'Not available' : value;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
