import 'package:flutter/material.dart';

import '../login_screen.dart';
import '../session.dart';
import '../ui/app_colors.dart';
import '../ui/app_text_styles.dart';
import '../ui/widgets/custom_button.dart';
import '../ui/widgets/custom_card.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/users_screen.dart';
import '../screens/admin/complaints_screen.dart';
import '../screens/admin/settings_screen.dart';

/// Admin shell: overview, users, drivers, services (verification, complaints, broadcasts).
class AdminShell extends StatefulWidget {
  const AdminShell({Key? key}) : super(key: key);

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: IndexedStack(
        index: _index,
        children: [
          const AdminDashboardScreen(),
          const UsersScreen(),
          const ComplaintsScreen(),
          const AdminSettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceBlack,
          border: Border(
            top: BorderSide(color: AppColors.borderGray, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.people_outline, Icons.people, 'Users', 1),
                _buildNavItem(Icons.report_problem_outlined, Icons.report_problem, 'Complaints', 2),
                _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.pureWhite : AppColors.silverMid,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.pureWhite : AppColors.silverMid,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
