import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_card.dart';
import '../../backend_config.dart';
import 'verifications_screen.dart';
import 'complaints_screen.dart';
import 'announcements_screen.dart';
import 'payment_config_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final statsResponse = await http.get(
        Uri.parse('$backendUrl/api/admin/stats'),
      );
      
      final activityResponse = await http.get(
        Uri.parse('$backendUrl/api/admin/recent-activity'),
      );

      if (statsResponse.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(statsResponse.body)['stats'] ?? {};
        });
      }

      if (activityResponse.statusCode == 200) {
        setState(() {
          _recentActivity = jsonDecode(activityResponse.body)['activity'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _stats['totalUsers'] ?? 0;
    final activeRides = _stats['activeRides'] ?? 0;
    final pendingVerifications = _stats['pendingVerifications'] ?? 0;
    final openComplaints = _stats['openComplaints'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.pureWhite),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Admin Panel',
                              style: AppTextStyles.headingXL,
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.cardBlack,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderGray),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: AppColors.pureWhite,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _buildStatCard(
                              value: totalUsers.toString(),
                              label: 'Total Users',
                              icon: Icons.people,
                            ),
                            _buildStatCard(
                              value: activeRides.toString(),
                              label: 'Active Rides',
                              icon: Icons.directions_car,
                            ),
                            _buildStatCard(
                              value: pendingVerifications.toString(),
                              label: 'Pending Verif.',
                              icon: Icons.pending_actions,
                            ),
                            _buildStatCard(
                              value: openComplaints.toString(),
                              label: 'Open Complaints',
                              icon: Icons.report_problem,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Quick Actions
                        Text(
                          'QUICK ACTIONS',
                          style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildQuickActionChip(
                                icon: Icons.verified_user,
                                label: 'Verifications',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const VerificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildQuickActionChip(
                                icon: Icons.report_problem,
                                label: 'Complaints',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ComplaintsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildQuickActionChip(
                                icon: Icons.campaign,
                                label: 'Announcements',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AnnouncementsScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              _buildQuickActionChip(
                                icon: Icons.payments,
                                label: 'Payment Config',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const PaymentConfigScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Recent Activity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT ACTIVITY',
                              style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
                            ),
                            GestureDetector(
                              onTap: () {
                                // View all activity
                              },
                              child: Text(
                                'View all',
                                style: AppTextStyles.labelBold.copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (_recentActivity.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.history, color: AppColors.silverMid, size: 48),
                                const SizedBox(height: 12),
                                Text('No recent activity', style: AppTextStyles.bodyM),
                              ],
                            ),
                          )
                        else
                          ..._recentActivity.take(5).map((activity) => 
                            _buildActivityRow(activity),
                          ),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.silverMid, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headingXL.copyWith(fontSize: 28),
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

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.silverLight, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.pureWhite),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(dynamic activity) {
    final icon = _getActivityIcon(activity['type']);
    final color = _getActivityColor(activity['type']);
    final description = activity['description'] ?? 'Unknown activity';
    final time = activity['timeAgo'] ?? 'Just now';

    return Container(
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'user_registered':
        return Icons.person_add;
      case 'ride_created':
        return Icons.add_location;
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'complaint_filed':
        return Icons.report_problem;
      case 'verification_submitted':
        return Icons.verified_user;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'user_registered':
        return AppColors.successGreen;
      case 'ride_created':
        return AppColors.warningAmber;
      case 'booking_confirmed':
        return AppColors.successGreen;
      case 'complaint_filed':
        return AppColors.dangerRed;
      case 'verification_submitted':
        return AppColors.silverLight;
      default:
        return AppColors.silverMid;
    }
  }
}
