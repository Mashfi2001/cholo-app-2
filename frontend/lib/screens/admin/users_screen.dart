import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../ui/widgets/custom_input_field.dart';
import '../../backend_config.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  bool _isLoading = true;

  final List<String> _filters = ['All', 'Drivers', 'Passengers', 'Suspended'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/admin/users'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = data['users'] ?? [];
          _filteredUsers = _users;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = user['name']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final phone = user['phone']?.toString().toLowerCase() ?? '';
        
        bool matchesSearch = name.contains(query) || 
                            email.contains(query) || 
                            phone.contains(query);
        
        bool matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Drivers' && user['role'] == 'DRIVER') ||
            (_selectedFilter == 'Passengers' && user['role'] == 'PASSENGER') ||
            (_selectedFilter == 'Suspended' && user['isSuspended'] == true);
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _selectFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _filterUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Users',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomInputField(
                controller: _searchController,
                label: 'Search users...',
                icon: Icons.search,
              ),
            ),

            const SizedBox(height: 16),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () => _selectFilter(filter),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.pureWhite : AppColors.cardBlack,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected ? AppColors.pureWhite : AppColors.borderGray,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: AppTextStyles.bodyM.copyWith(
                            color: isSelected ? AppColors.primaryBlack : AppColors.silverLight,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // User list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, color: AppColors.silverMid, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: AppTextStyles.headingL.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            return _buildUserRow(user);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRow(dynamic user) {
    final name = user['name'] ?? 'Unknown';
    final role = user['role'] ?? 'PASSENGER';
    final isSuspended = user['isSuspended'] ?? false;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserDetailScreen(user: user),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceBlack,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderGray),
              ),
              child: const Icon(Icons.person, color: AppColors.silverLight),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyL.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: role == 'DRIVER'
                              ? AppColors.warningAmber.withOpacity(0.15)
                              : AppColors.silverMid.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role,
                          style: AppTextStyles.caption.copyWith(
                            color: role == 'DRIVER' 
                                ? AppColors.warningAmber 
                                : AppColors.silverMid,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSuspended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.dangerRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SUSPENDED',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.dangerRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.silverMid,
            ),
          ],
        ),
      ),
    );
  }
}
