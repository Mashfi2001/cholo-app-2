import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';
import 'create_route_screen.dart';
import 'active_session_screen.dart';

class DriverRoutesScreen extends StatefulWidget {
  const DriverRoutesScreen({super.key});

  @override
  State<DriverRoutesScreen> createState() => _DriverRoutesScreenState();
}

class _DriverRoutesScreenState extends State<DriverRoutesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _upcomingRoutes = [];
  List<dynamic> _activeRoutes = [];
  List<dynamic> _completedRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRoutes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/rides/driver/${Session.userId}/routes'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _upcomingRoutes = data['upcoming'] ?? [];
          _activeRoutes = data['active'] ?? [];
          _completedRoutes = data['completed'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading routes: $e');
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Routes',
                    style: AppTextStyles.headingXL,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRouteScreen(),
                        ),
                      ).then((_) => _loadRoutes());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primaryBlack,
                        size: 20,
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRoutesList(_upcomingRoutes, 'upcoming'),
                        _buildRoutesList(_activeRoutes, 'active'),
                        _buildRoutesList(_completedRoutes, 'completed'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesList(List<dynamic> routes, String type) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'completed' ? Icons.check_circle : Icons.route,
              color: AppColors.silverMid,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(type),
              style: AppTextStyles.headingL.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            if (type == 'upcoming')
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateRouteScreen(),
                    ),
                  ).then((_) => _loadRoutes());
                },
                child: Text(
                  'Create a route',
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.pureWhite,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return _buildRouteCard(route, type);
      },
    );
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case 'upcoming':
        return 'No upcoming routes';
      case 'active':
        return 'No active rides';
      case 'completed':
        return 'No completed rides yet';
      default:
        return 'No routes';
    }
  }

  Widget _buildRouteCard(dynamic route, String type) {
    final origin = route['origin']?['name'] ?? route['origin'] ?? 'Unknown';
    final destination = route['destination']?['name'] ?? route['destination'] ?? 'Unknown';
    final date = route['date'] ?? '';
    final time = route['time'] ?? '';
    final totalSeats = route['totalSeats'] ?? 0;
    final bookedSeats = route['bookedSeats'] ?? 0;
    final farePerSeat = route['farePerSeat'] ?? 0;

    return GestureDetector(
      onTap: () {
        if (type == 'active') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveSessionScreen(ride: route),
            ),
          );
        }
      },
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusBadge(type),
                const Spacer(),
                if (type == 'active')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Live',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Route info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        origin.toString().split(',')[0],
                        style: AppTextStyles.headingL.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        date,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_forward, color: AppColors.silverLight, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: AppTextStyles.labelBold,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        destination.toString().split(',')[0],
                        style: AppTextStyles.headingL.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.borderGray),
            const SizedBox(height: 12),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.event_seat, '$bookedSeats/$totalSeats seats'),
                _buildStatItem(Icons.payments, '৳$farePerSeat'),
                if (type != 'completed')
                  Text(
                    'Tap to manage →',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.silverLight,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String type) {
    final (text, color) = switch (type) {
      'upcoming' => ('Upcoming', AppColors.warningAmber),
      'active' => ('Active', AppColors.successGreen),
      'completed' => ('Completed', AppColors.silverMid),
      _ => ('Unknown', AppColors.silverMid),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.silverMid, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.bodyM,
        ),
      ],
    );
  }
}
