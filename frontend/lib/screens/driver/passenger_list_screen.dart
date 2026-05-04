import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../backend_config.dart';

class PassengerListScreen extends StatefulWidget {
  final dynamic ride;
  final List<dynamic> confirmedPassengers;
  final List<dynamic> pendingRequests;

  const PassengerListScreen({
    super.key,
    required this.ride,
    required this.confirmedPassengers,
    required this.pendingRequests,
  });

  @override
  State<PassengerListScreen> createState() => _PassengerListScreenState();
}

class _PassengerListScreenState extends State<PassengerListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _rejectedPassengers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRejectedPassengers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRejectedPassengers() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/rides/${widget.ride['id']}/rejected-requests'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rejectedPassengers = data['requests'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading rejected passengers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadRejectedPassengers();
    setState(() => _isLoading = false);
  }

  Future<void> _callPassenger(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.confirmedPassengers.length + 
                  widget.pendingRequests.length + 
                  _rejectedPassengers.length;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passengers',
                          style: AppTextStyles.headingM,
                        ),
                        Text(
                          '$total total · ${widget.confirmedPassengers.length} confirmed · ${widget.pendingRequests.length} pending',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
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
                  Tab(text: 'Confirmed'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Rejected'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildConfirmedTab(),
                  _buildPendingTab(),
                  _buildRejectedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmedTab() {
    if (widget.confirmedPassengers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'No confirmed passengers',
        subtitle: 'Accepted passengers will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.pureWhite,
      backgroundColor: AppColors.cardBlack,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: widget.confirmedPassengers.length,
        itemBuilder: (context, index) {
          final passenger = widget.confirmedPassengers[index];
          return _buildPassengerRow(
            passenger: passenger,
            status: 'Confirmed',
            statusColor: AppColors.successGreen,
            showPhone: true,
          );
        },
      ),
    );
  }

  Widget _buildPendingTab() {
    if (widget.pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'No pending requests',
        subtitle: 'New booking requests will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.pureWhite,
      backgroundColor: AppColors.cardBlack,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: widget.pendingRequests.length,
        itemBuilder: (context, index) {
          final request = widget.pendingRequests[index];
          return _buildPassengerRow(
            passenger: request,
            status: 'Pending',
            statusColor: AppColors.warningAmber,
            showPhone: false,
          );
        },
      ),
    );
  }

  Widget _buildRejectedTab() {
    if (_rejectedPassengers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.cancel,
        title: 'No rejected requests',
        subtitle: 'Rejected bookings will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.pureWhite,
      backgroundColor: AppColors.cardBlack,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _rejectedPassengers.length,
        itemBuilder: (context, index) {
          final passenger = _rejectedPassengers[index];
          return _buildPassengerRow(
            passenger: passenger,
            status: 'Rejected',
            statusColor: AppColors.dangerRed,
            showPhone: false,
          );
        },
      ),
    );
  }

  Widget _buildPassengerRow({
    required dynamic passenger,
    required String status,
    required Color statusColor,
    required bool showPhone,
  }) {
    final name = passenger['passenger']?['name'] ?? 'Unknown';
    final phone = passenger['passenger']?['phone'] ?? '';
    final pickup = passenger['pickupStop']?.toString() ?? 'Pickup location';
    final seats = passenger['seats'] ?? 1;

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
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlack,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderGray),
            ),
            child: const Icon(Icons.person, color: AppColors.silverLight),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pickup: $pickup',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$seats seat${seats > 1 ? 's' : ''}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          // Phone button
          if (showPhone && phone.isNotEmpty)
            IconButton(
              onPressed: () => _callPassenger(phone),
              icon: const Icon(Icons.phone, color: AppColors.successGreen),
            ),
        ],
      ),
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
}
