import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';
import '../../screens/auth/login_screen.dart';
import 'verification_screen.dart';
import 'driver_complaint_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final String userName;

  const DriverProfileScreen({super.key, required this.userName});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/profile'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profile = data['driver'];
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _logout() {
    Session.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerified = _profile?['isVerified'] ?? false;
    final isPending = _profile?['verificationStatus'] == 'PENDING';
    final totalRides = _profile?['totalRides'] ?? 0;
    final rating = _profile?['rating']?.toStringAsFixed(1) ?? '0.0';
    final earnings = _profile?['totalEarnings'] ?? 0;
    final phone = _profile?['phone'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.pureWhite),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48),
                        Text(
                          'My Profile',
                          style: AppTextStyles.headingM,
                        ),
                        IconButton(
                          onPressed: () {
                            // Navigate to edit profile
                          },
                          icon: const Icon(Icons.edit, color: AppColors.pureWhite),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Hero section
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.pureWhite, width: 3),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.pureWhite,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.userName,
                      style: AppTextStyles.headingL,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: AppTextStyles.bodyM,
                    ),

                    const SizedBox(height: 24),

                    // Verification banner
                    if (!isVerified && !isPending)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warningAmber),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.warningAmber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.warningAmber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Pending Verification',
                                    style: AppTextStyles.bodyL.copyWith(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const VerificationScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Submit Documents →',
                                      style: AppTextStyles.labelBold.copyWith(
                                        color: AppColors.warningAmber,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isPending)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warningAmber),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.warningAmber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.hourglass_top,
                                color: AppColors.warningAmber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verification Under Review',
                                    style: AppTextStyles.bodyL.copyWith(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'We\'re reviewing your documents. This usually takes 24 hours.',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.successGreen),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: AppColors.successGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Verified Driver',
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            value: totalRides.toString(),
                            label: 'Total Rides',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            value: rating,
                            label: 'Rating',
                            icon: Icons.star,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            value: '৳$earnings',
                            label: 'Earnings',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Menu list
                    CustomCard(
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.directions_car,
                            title: 'My Vehicle',
                            onTap: () {},
                          ),
                          Divider(color: AppColors.borderGray, height: 1),
                          _buildMenuItem(
                            icon: Icons.description,
                            title: 'Documents',
                            subtitle: 'NID / License',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const VerificationScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(color: AppColors.borderGray, height: 1),
                          _buildMenuItem(
                            icon: Icons.route,
                            title: 'My Routes',
                            onTap: () {},
                          ),
                          Divider(color: AppColors.borderGray, height: 1),
                          _buildMenuItem(
                            icon: Icons.notifications,
                            title: 'Notifications',
                            onTap: () {},
                          ),
                          Divider(color: AppColors.borderGray, height: 1),
                          _buildMenuItem(
                            icon: Icons.report_problem,
                            title: 'File Complaint',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const DriverComplaintScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(color: AppColors.borderGray, height: 1),
                          _buildMenuItem(
                            icon: Icons.lock,
                            title: 'Change Password',
                            onTap: () {},
                          ),
                          Divider(color: AppColors.borderGray, height: 1),
                          _buildMenuItem(
                            icon: Icons.logout,
                            title: 'Logout',
                            textColor: AppColors.dangerRed,
                            onTap: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.warningAmber, size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: AppTextStyles.headingL.copyWith(fontSize: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.silverLight, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyL.copyWith(
                      color: textColor ?? AppColors.pureWhite,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textColor ?? AppColors.silverMid,
            ),
          ],
        ),
      ),
    );
  }
}
