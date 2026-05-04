import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';
import 'active_ride_screen.dart';
import 'rate_review_screen.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});

  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _upcomingRides = [];
  List<dynamic> _activeRides = [];
  List<dynamic> _completedRides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRides() async {
    if (Session.userId == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/seat-booking/passenger/${Session.userId}/history'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rides = data['rides'] ?? [];

        setState(() {
          _upcomingRides = rides.where((r) =>
            r['status'] == 'PENDING' || r['status'] == 'APPROVED'
          ).toList();
          _activeRides = rides.where((r) =>
            r['status'] == 'ACTIVE' || r['status'] == 'ONGOING'
          ).toList();
          _completedRides = rides.where((r) =>
            r['status'] == 'COMPLETED' || r['status'] == 'CANCELLED'
          ).toList();
        });
      }
    } catch (e) {
      print('Error loading rides: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
              child: Text(
                'My Rides',
                style: AppTextStyles.headingXL,
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primaryBlack,
                unselectedLabelColor: AppColors.silverMid,
                labelStyle: AppTextStyles.labelBold.copyWith(fontSize: 12),
                unselectedLabelStyle: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingTab(),
                  _buildActiveTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pureWhite),
      );
    }

    if (_upcomingRides.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        title: 'No upcoming rides',
        subtitle: 'Book a ride to see it here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _upcomingRides.length,
      itemBuilder: (context, index) {
        final ride = _upcomingRides[index];
        return _buildUpcomingRideCard(ride);
      },
    );
  }

  Widget _buildActiveTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pureWhite),
      );
    }

    if (_activeRides.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_taxi,
        title: 'No active rides',
        subtitle: 'Your ongoing rides will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _activeRides.length,
      itemBuilder: (context, index) {
        final ride = _activeRides[index];
        return _buildActiveRideCard(ride);
      },
    );
  }

  Widget _buildCompletedTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pureWhite),
      );
    }

    if (_completedRides.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'No completed rides',
        subtitle: 'Your ride history will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _completedRides.length,
      itemBuilder: (context, index) {
        final ride = _completedRides[index];
        return _buildCompletedRideCard(ride);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.silverMid, size: 64),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.headingL.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodyM),
        ],
      ),
    );
  }

  Widget _buildUpcomingRideCard(dynamic ride) {
    final origin = ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = ride['destination']?.toString().split(',').first ?? 'Unknown';
    final dateTime = _formatDateTime(ride['departureTime'] ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.warningAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule,
                    color: AppColors.warningAmber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$origin → $destination',
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(dateTime, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Cancel',
              variant: CustomButtonVariant.secondary,
              onPressed: () => _showCancelConfirmation(ride),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRideCard(dynamic ride) {
    final origin = ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = ride['destination']?.toString().split(',').first ?? 'Unknown';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: AppColors.successGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'IN PROGRESS',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$origin → $destination',
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Track Ride',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveRideScreen(ride: ride),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedRideCard(dynamic ride) {
    final origin = ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = ride['destination']?.toString().split(',').first ?? 'Unknown';
    final isRated = ride['isRated'] == true;
    final rating = ride['rating'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.silverLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$origin → $destination',
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(ride['completedAt'] ?? ride['departureTime'] ?? ''),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isRated)
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: index < rating ? AppColors.warningAmber : AppColors.borderGray,
                    size: 18,
                  );
                }),
              )
            else
              CustomButton(
                label: 'Rate Now',
                variant: CustomButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RateReviewScreen(ride: ride),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(dynamic ride) {
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
              Icons.warning_amber_rounded,
              color: AppColors.warningAmber,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Cancel Booking?',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to cancel this ride?',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Yes, Cancel',
              variant: CustomButtonVariant.danger,
              onPressed: () {
                Navigator.pop(context);
                // Cancel API call
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Keep Booking',
              variant: CustomButtonVariant.secondary,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$day/$month at $hour:$minute $suffix';
    } catch (e) {
      return '';
    }
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      return '$day/$month/$year';
    } catch (e) {
      return '';
    }
  }
}
