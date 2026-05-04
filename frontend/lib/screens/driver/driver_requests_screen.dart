import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_card.dart';
import '../../ui/widgets/custom_button.dart';
import '../../session.dart';
import '../../backend_config.dart';
import 'passenger_request_card.dart';

class DriverRequestsScreen extends StatefulWidget {
  const DriverRequestsScreen({super.key});

  @override
  State<DriverRequestsScreen> createState() => _DriverRequestsScreenState();
}

class _DriverRequestsScreenState extends State<DriverRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingRequests = [];
  List<dynamic> _confirmedPassengers = [];
  List<dynamic> _pastRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/all-requests'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingRequests = data['pending'] ?? [];
          _confirmedPassengers = data['confirmed'] ?? [];
          _pastRequests = data['past'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading requests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccept(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/requests/$requestId/accept'),
      );

      if (response.statusCode == 200) {
        _loadRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted', style: AppTextStyles.bodyL),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      print('Error accepting request: $e');
    }
  }

  Future<void> _handleReject(int requestId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/requests/$requestId/reject'),
      );

      if (response.statusCode == 200) {
        _loadRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request declined', style: AppTextStyles.bodyL),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      print('Error rejecting request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Passenger Requests',
                    style: AppTextStyles.headingXL,
                  ),
                  if (_pendingRequests.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${_pendingRequests.length} pending',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: AppColors.primaryBlack,
                unselectedLabelColor: AppColors.silverMid,
                labelStyle: AppTextStyles.labelBold,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                tabs: [
                  Tab(text: 'Pending (${_pendingRequests.length})'),
                  Tab(text: 'Confirmed'),
                  Tab(text: 'History'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPendingTab(),
                        _buildConfirmedTab(),
                        _buildHistoryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, color: AppColors.silverMid, size: 64),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: AppTextStyles.headingL.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Requests will appear when passengers book your routes',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _pendingRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingRequests[index];
        return PassengerRequestCard(
          request: request,
          onAccept: () => _handleAccept(request['id']),
          onReject: () => _handleReject(request['id']),
        );
      },
    );
  }

  Widget _buildConfirmedTab() {
    if (_confirmedPassengers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, color: AppColors.silverMid, size: 64),
            const SizedBox(height: 16),
            Text(
              'No confirmed passengers',
              style: AppTextStyles.headingL.copyWith(fontSize: 20),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _confirmedPassengers.length,
      itemBuilder: (context, index) {
        final passenger = _confirmedPassengers[index];
        return _buildConfirmedCard(passenger);
      },
    );
  }

  Widget _buildConfirmedCard(dynamic passenger) {
    final name = passenger['passengerName'] ?? 'Unknown';
    final seats = passenger['requestedSeats'] ?? 1;
    final ride = passenger['ride'] ?? {};
    final origin = ride['origin']?['name'] ?? ride['origin'] ?? 'Unknown';
    final destination = ride['destination']?['name'] ?? ride['destination'] ?? 'Unknown';
    final date = ride['date'] ?? '';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.successGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$seats seat${seats > 1 ? 's' : ''} • $date',
                  style: AppTextStyles.bodyM,
                ),
                const SizedBox(height: 4),
                Text(
                  '$origin → $destination',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_pastRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: AppColors.silverMid, size: 64),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: AppTextStyles.headingL.copyWith(fontSize: 20),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _pastRequests.length,
      itemBuilder: (context, index) {
        final request = _pastRequests[index];
        final status = request['status'] ?? 'unknown';
        final isAccepted = status == 'accepted' || status == 'confirmed';

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppColors.silverMid.withOpacity(0.15)
                      : AppColors.dangerRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAccepted ? Icons.check : Icons.close,
                  color: isAccepted ? AppColors.silverMid : AppColors.dangerRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['passengerName'] ?? 'Unknown',
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${request['requestedSeats'] ?? 1} seat(s) • $status',
                      style: AppTextStyles.caption.copyWith(
                        color: isAccepted ? AppColors.silverMid : AppColors.dangerRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
