import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../backend_config.dart';
import '../screens/auth/login_screen.dart';
import '../screens/passenger/home_screen.dart';
import '../screens/passenger/search_rides_screen.dart';
import '../screens/passenger/my_rides_screen.dart';
import '../screens/passenger/file_complaint_screen.dart';
import '../session.dart';
import '../user_profile_page.dart';
import '../verification_request_page.dart';
import '../ui/app_colors.dart';
import '../ui/app_text_styles.dart';
import '../ui/widgets/custom_button.dart';
import '../ui/widgets/custom_card.dart';

/// Passenger app shell: Home → Find ride → My rides → Account.
class PassengerShell extends StatefulWidget {
  final int userId;
  final String userName;

  const PassengerShell({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  int _index = 0;
  List<dynamic> _notifications = [];
  bool _homeLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    if (Session.userId == null) return;
    setState(() => _homeLoading = true);
    try {
      final notifRes = await http.get(
        Uri.parse('$backendUrl/api/notifications/user/${Session.userId}'),
      );
      final userRes = await http.get(
        Uri.parse(
          '$backendUrl/api/complaints/passenger/${Session.userId}/history',
        ),
      );
      if (notifRes.statusCode == 200 && userRes.statusCode == 200) {
        final notifBody = jsonDecode(notifRes.body);
        setState(() {
          _notifications =
              List<dynamic>.from(notifBody['notifications'] ?? []);
          _userData = jsonDecode(userRes.body) as Map<String, dynamic>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _homeLoading = false);
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, i) {
                    final n = _notifications[i];
                    return ListTile(
                      leading: Icon(
                        n['type'] == 'WARNING'
                            ? Icons.warning
                            : n['type'] == 'SUCCESS'
                                ? Icons.check_circle
                                : Icons.info,
                        color: AppColors.textSecondary,
                      ),
                      title: Text(
                        n['title'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        n['message'].toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (_index) {
      case 0:
        return '';
      case 1:
        return 'Find a Ride';
      case 2:
        return 'My Rides';
      case 3:
        return 'Account';
      default:
        return '';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_index == 0) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: _showNotificationsDialog,
                ),
                if (_notifications.any((n) => n['isRead'] == false))
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadHome,
            ),
          ],
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          PassengerHomeScreen(userName: widget.userName),
          const SearchRidesScreen(),
          const MyRidesScreen(),
          _buildAccountTab(),
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
                _buildNavItem(Icons.search, Icons.search, 'Find', 1),
                _buildNavItem(Icons.event_seat_outlined, Icons.event_seat, 'Rides', 2),
                _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Home tab is now handled by PassengerHomeScreen

  Widget _stepRow(String n, String t, String d) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface,
            child: Text(
              n,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(d, style: AppTextStyles.body.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(dynamic n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            n['title'].toString(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            n['message'].toString(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _statusBanner() {
    final banned = _userData?['isBanned'] == true;
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            banned ? Icons.block : Icons.warning_amber_rounded,
            color: banned ? AppColors.danger : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              banned
                  ? 'Your account has restrictions. Check notifications for details.'
                  : 'You have warnings on your account. Please follow community guidelines.',
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CustomCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                Session.userEmail ?? 'Signed in',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _accountTile(
          icon: Icons.badge_outlined,
          title: 'Profile',
          subtitle: 'View your public profile details',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfilePage(
                  user: {
                    'id': widget.userId,
                    'name': widget.userName,
                    'email': Session.userEmail ?? '—',
                    'role': 'PASSENGER',
                  },
                ),
              ),
            );
          },
        ),
        _accountTile(
          icon: Icons.verified_user_outlined,
          title: 'Verify identity',
          subtitle: 'Submit documents for driver or trust badges',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => VerificationRequestPage(
                  userId: widget.userId,
                  userName: widget.userName,
                ),
              ),
            );
          },
        ),
        _accountTile(
          icon: Icons.help_outline,
          title: 'Help & support',
          subtitle: 'Contact us if something goes wrong',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Support: use in-app complaints from ride details.'),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        CustomButton(
          label: 'Log out',
          icon: Icons.logout,
          variant: CustomButtonVariant.secondary,
          onPressed: () {
            Session.clear();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _accountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: Icon(icon, color: AppColors.textSecondary),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: onTap,
        ),
      ),
    );
  }
}
