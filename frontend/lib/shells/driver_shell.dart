import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../login_screen.dart';
import '../session.dart';
import '../backend_config.dart';
import '../ui/app_colors.dart';
import '../ui/app_text_styles.dart';
import '../ui/widgets/custom_button.dart';
import '../ui/widgets/custom_card.dart';
import '../screens/driver/driver_home_screen.dart';
import '../screens/driver/driver_profile_screen.dart';
import '../screens/driver/driver_routes_screen.dart';
import '../screens/driver/driver_requests_screen.dart';

/// Driver shell: Home overview, My rides list, Account. Full-screen ride planner via FAB.
class DriverShell extends StatefulWidget {
  final int userId;
  final String userName;

  const DriverShell({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _index = 0;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/pending-requests-count'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingRequestsCount = data['count'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading pending requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: IndexedStack(
        index: _index,
        children: [
          DriverHomeScreen(userName: widget.userName),
          const DriverRoutesScreen(),
          const DriverRequestsScreen(),
          DriverProfileScreen(userName: widget.userName),
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
                _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                _buildNavItem(Icons.route, Icons.route, 'Routes', 1),
                _buildNavItem(
                  Icons.notifications_outlined,
                  Icons.notifications,
                  'Requests',
                  2,
                  badge: _pendingRequestsCount > 0 ? _pendingRequestsCount : null,
                ),
                _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index, {
    int? badge,
  }) {
    final isSelected = _index == index;
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? AppColors.pureWhite : AppColors.silverMid,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.dangerRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : badge.toString(),
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
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

