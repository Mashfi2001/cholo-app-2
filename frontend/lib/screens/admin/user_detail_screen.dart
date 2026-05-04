import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../backend_config.dart';

class UserDetailScreen extends StatefulWidget {
  final dynamic user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = false;

  Future<void> _suspendAccount() async {
    final reasonController = TextEditingController();
    
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceBlack,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.block,
                color: AppColors.dangerRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Suspend Account?',
                style: AppTextStyles.headingL,
              ),
              const SizedBox(height: 8),
              Text(
                'This will prevent the user from accessing the app.',
                style: AppTextStyles.bodyM,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: 'Enter suspension reason...',
                    hintStyle: AppTextStyles.bodyM,
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Suspend Account',
                variant: CustomButtonVariant.danger,
                onPressed: () {
                  if (reasonController.text.trim().isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Cancel',
                variant: CustomButtonVariant.secondary,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/users/${widget.user['id']}/suspend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reasonController.text.trim()}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account suspended',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error suspending: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reinstateAccount() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.restore,
              color: AppColors.successGreen,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Reinstate Account?',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'This will restore the user\'s access to the app.',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Reinstate',
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Cancel',
              variant: CustomButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/users/${widget.user['id']}/reinstate'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account reinstated',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error reinstating: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAccount() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.delete_forever,
              color: AppColors.dangerRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Remove Account?',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone. All user data will be permanently deleted.',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Remove Account',
              variant: CustomButtonVariant.danger,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Cancel',
              variant: CustomButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/admin/users/${widget.user['id']}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account removed',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error removing: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] ?? 'Unknown';
    final email = widget.user['email'] ?? '';
    final phone = widget.user['phone'] ?? '';
    final role = widget.user['role'] ?? 'PASSENGER';
    final isSuspended = widget.user['isSuspended'] ?? false;
    final isVerified = widget.user['isVerified'] ?? false;
    final joinedAt = widget.user['createdAt'] ?? '';
    final totalRides = widget.user['totalRides'] ?? 0;
    final rating = widget.user['rating']?.toStringAsFixed(1) ?? '0.0';

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'User Details',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Profile header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderGray, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.pureWhite,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: AppTextStyles.headingL,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: role == 'DRIVER'
                                ? AppColors.warningAmber.withOpacity(0.15)
                                : AppColors.silverMid.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(100),
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.dangerRed.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
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
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'VERIFIED',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.successGreen,
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

              const SizedBox(height: 32),

              // Info sections
              _buildInfoSection('Contact Information', [
                _buildInfoRow(Icons.email, 'Email', email),
                _buildInfoRow(Icons.phone, 'Phone', phone),
              ]),

              const SizedBox(height: 24),

              _buildInfoSection('Account Details', [
                _buildInfoRow(Icons.calendar_today, 'Joined', _formatDate(joinedAt)),
                _buildInfoRow(Icons.directions_car, 'Total Rides', totalRides.toString()),
                _buildInfoRow(Icons.star, 'Rating', '$rating ★'),
              ]),

              const SizedBox(height: 32),

              // Action buttons
              if (isSuspended)
                CustomButton(
                  label: 'Reinstate Account',
                  onPressed: _isLoading ? null : _reinstateAccount,
                  isLoading: _isLoading,
                )
              else ...[
                CustomButton(
                  label: 'Suspend Account',
                  variant: CustomButtonVariant.secondary,
                  onPressed: _isLoading ? null : _suspendAccount,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Remove Account',
                  variant: CustomButtonVariant.danger,
                  onPressed: _isLoading ? null : _removeAccount,
                  isLoading: _isLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.silverMid, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyM,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
