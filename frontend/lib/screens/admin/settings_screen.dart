import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../screens/auth/login_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  void _logout(BuildContext context) {
    Session.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  'Settings',
                  style: AppTextStyles.headingXL,
                ),
              ),

              // Admin profile card
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBlack,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderGray, width: 2),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.pureWhite,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator',
                            style: AppTextStyles.headingL.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Session.userEmail ?? 'admin@cholo.app',
                            style: AppTextStyles.bodyM,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Settings menu
              CustomCard(
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: 'System Notifications',
                      onTap: () {},
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildMenuItem(
                      icon: Icons.security,
                      title: 'Security Settings',
                      onTap: () {},
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildMenuItem(
                      icon: Icons.backup,
                      title: 'Backup & Restore',
                      onTap: () {},
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildMenuItem(
                      icon: Icons.analytics,
                      title: 'System Logs',
                      onTap: () {},
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      textColor: AppColors.dangerRed,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // App info
              Center(
                child: Text(
                  'Cholo Admin v1.0.0',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
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
              child: Text(
                title,
                style: AppTextStyles.bodyL.copyWith(
                  color: textColor ?? AppColors.pureWhite,
                  fontWeight: FontWeight.w500,
                ),
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
