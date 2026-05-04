import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';
import 'search_rides_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  final String userName;

  const PassengerHomeScreen({
    super.key,
    required this.userName,
  });

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  List<dynamic> _recentRides = [];
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    if (Session.userId == null) return;
    setState(() => _isLoading = true);
    try {
      // Fetch recent rides
      final ridesRes = await http.get(
        Uri.parse('$backendUrl/seat-booking/passenger/${Session.userId}/history'),
      );

      // Fetch notifications
      final notifRes = await http.get(
        Uri.parse('$backendUrl/api/notifications/user/${Session.userId}'),
      );

      if (ridesRes.statusCode == 200 && notifRes.statusCode == 200) {
        final ridesData = jsonDecode(ridesRes.body);
        final notifData = jsonDecode(notifRes.body);
        setState(() {
          _recentRides = ridesData['rides']?.take(5).toList() ?? [];
          _notifications = notifData['notifications'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // Map area (top 45%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _userLocation ?? const LatLng(23.8103, 90.4125),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.cholo',
                ),
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation!,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlack,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlack,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Top bar with avatar and greeting
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.silverLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting,',
                          style: AppTextStyles.caption,
                        ),
                        Text(
                          widget.userName.split(' ').first,
                          style: AppTextStyles.bodyL.copyWith(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.silverLight,
                          size: 22,
                        ),
                        onPressed: _showNotifications,
                      ),
                    ),
                    if (_notifications.any((n) => n['isRead'] == false))
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.dangerRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom sheet (persistent)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: const BoxDecoration(
                color: AppColors.surfaceBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.borderGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WHERE ARE YOU GOING?',
                            style: AppTextStyles.caption.copyWith(
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Search bar
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SearchRidesScreen(),
                                ),
                              );
                            },
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.cardBlack,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderGray),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.search,
                                    color: AppColors.pureWhite,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Enter destination',
                                    style: AppTextStyles.bodyM,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Divider(
                            color: AppColors.borderGray,
                            height: 1,
                          ),
                          const SizedBox(height: 20),
                          // Recent rides section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RECENT RIDES',
                                style: AppTextStyles.caption.copyWith(
                                  letterSpacing: 1,
                                ),
                              ),
                              if (_recentRides.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to My Rides
                                  },
                                  child: Text(
                                    'See All',
                                    style: AppTextStyles.labelBold.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Recent rides horizontal scroll
                          if (_recentRides.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.directions_car_outlined,
                                      color: AppColors.silverMid,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No recent rides',
                                      style: AppTextStyles.bodyM,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentRides.length,
                                itemBuilder: (context, index) {
                                  final ride = _recentRides[index];
                                  return _buildRecentRideChip(ride);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRideChip(dynamic ride) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.successGreen,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  ride['origin']?.toString().split(',').first ?? 'Unknown',
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.arrow_forward,
                  color: AppColors.silverMid,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  ride['destination']?.toString().split(',').first ?? 'Unknown',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surfaceBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.headingL,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.silverLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            color: AppColors.silverMid,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: AppTextStyles.bodyM,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return _buildNotificationItem(n);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(dynamic n) {
    IconData icon = Icons.info_outline;
    Color color = AppColors.silverLight;

    if (n['type'] == 'WARNING') {
      icon = Icons.warning_amber_rounded;
      color = AppColors.warningAmber;
    } else if (n['type'] == 'DANGER') {
      icon = Icons.error_outline;
      color = AppColors.dangerRed;
    } else if (n['type'] == 'SUCCESS') {
      icon = Icons.check_circle_outline;
      color = AppColors.successGreen;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['title'].toString(),
                    style: AppTextStyles.bodyL.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['message'].toString(),
                    style: AppTextStyles.bodyM,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
