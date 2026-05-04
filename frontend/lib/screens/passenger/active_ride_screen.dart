import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';

class ActiveRideScreen extends StatelessWidget {
  final dynamic ride;

  const ActiveRideScreen({
    super.key,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    final driverName = ride['driver']?['name'] ?? 'Driver';
    final driverRating = ride['driver']?['rating']?.toStringAsFixed(1) ?? '4.5';
    final origin = ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = ride['destination']?.toString().split(',').first ?? 'Unknown';

    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(23.8103, 90.4125),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.cholo',
              ),
            ],
          ),

          // Top overlay card
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.frostedOverlay,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderGray.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // In Progress badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'IN PROGRESS',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Route
                        Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.successGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppColors.silverMid.withOpacity(0.5),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.pureWhite,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    origin,
                                    style: AppTextStyles.bodyL.copyWith(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    destination,
                                    style: AppTextStyles.bodyL.copyWith(
                                      color: AppColors.pureWhite,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '~12 min remaining',
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.silverLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBlack,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceBlack,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Driver info row
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.cardBlack,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.silverLight,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: AppTextStyles.headingL.copyWith(fontSize: 18),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.warningAmber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    driverRating,
                                    style: AppTextStyles.bodyM,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Toyota Corolla • DH-12-3456',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.phone,
                            label: 'Call',
                            onTap: () => _callDriver(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.chat_bubble,
                            label: 'Chat',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => RideChatScreen(
                                    rideId: ride['id'],
                                    rideTitle: '$origin to $destination',
                                    otherUserId: ride['driver']?['id'],
                                    otherUserName: driverName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // SOS button
                    SizedBox(
                      height: 44,
                      child: CustomButton(
                        label: 'SOS / Emergency',
                        variant: CustomButtonVariant.danger,
                        onPressed: () => _showEmergencySheet(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.silverLight),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodyM,
            ),
          ],
        ),
      ),
    );
  }

  void _callDriver(BuildContext context) async {
    final phoneNumber = ride['driver']?['phone'] ?? '+8801234567890';
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not launch phone app',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet(
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
              Icons.emergency,
              color: AppColors.dangerRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Emergency Contacts',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'Call emergency services or our support team',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Call 999 (Police)',
              variant: CustomButtonVariant.danger,
              onPressed: () async {
                final Uri url = Uri.parse('tel:999');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Call Support',
              variant: CustomButtonVariant.secondary,
              onPressed: () async {
                final Uri url = Uri.parse('tel:+8801234567890');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for RideChatScreen - will use existing implementation
class RideChatScreen extends StatelessWidget {
  final int rideId;
  final String rideTitle;
  final dynamic otherUserId;
  final String otherUserName;

  const RideChatScreen({
    super.key,
    required this.rideId,
    required this.rideTitle,
    this.otherUserId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBlack,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(otherUserName, style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite)),
            Text(rideTitle, style: AppTextStyles.caption),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.silverMid, size: 64),
            const SizedBox(height: 16),
            Text('Chat feature coming soon', style: AppTextStyles.bodyM),
          ],
        ),
      ),
    );
  }
}
