import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';
import 'create_route_screen.dart';
import 'active_session_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  final String userName;

  const DriverHomeScreen({super.key, required this.userName});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = false;
  bool _isLoading = true;
  dynamic _currentRoute;
  int _pendingRequests = 0;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadDriverStatus();
  }

  Future<void> _loadDriverStatus() async {
    try {
      // Check driver status
      final statusResponse = await http.get(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/status'),
      );

      if (statusResponse.statusCode == 200) {
        final statusData = jsonDecode(statusResponse.body);
        setState(() {
          _isOnline = statusData['isOnline'] ?? false;
        });
      }

      // Check for current route
      final routeResponse = await http.get(
        Uri.parse('$backendUrl/api/rides/driver/${Session.userId}/active'),
      );

      if (routeResponse.statusCode == 200) {
        final routeData = jsonDecode(routeResponse.body);
        setState(() {
          _currentRoute = routeData['ride'];
        });
      }

      // Get pending requests count
      if (_currentRoute != null) {
        final requestsResponse = await http.get(
          Uri.parse('$backendUrl/api/rides/${_currentRoute['id']}/pending-requests'),
        );

        if (requestsResponse.statusCode == 200) {
          final requestsData = jsonDecode(requestsResponse.body);
          setState(() {
            _pendingRequests = (requestsData['requests'] as List?)?.length ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading driver status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnlineStatus() async {
    final newStatus = !_isOnline;
    
    if (!newStatus) {
      // Show confirmation before going offline
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildOfflineConfirmationSheet(),
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isOnline': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() => _isOnline = newStatus);
      }
    } catch (e) {
      print('Error updating status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.pureWhite),
            )
          : Stack(
              children: [
                // Map area (top 45%)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: FlutterMap(
                    mapController: _mapController,
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
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: const LatLng(23.8103, 90.4125),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isOnline ? AppColors.successGreen : AppColors.silverMid,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.pureWhite, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isOnline ? AppColors.successGreen : AppColors.silverMid).withOpacity(0.4),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: AppColors.pureWhite,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // App bar overlay
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.cardBlack,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: const Icon(Icons.person, color: AppColors.pureWhite, size: 20),
                        ),
                        const SizedBox(width: 12),
                        
                        // Greeting
                        Expanded(
                          child: Text(
                            'Good morning, ${widget.userName}',
                            style: AppTextStyles.bodyL.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Status badge
                        GestureDetector(
                          onTap: _toggleOnlineStatus,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isOnline 
                                  ? AppColors.successGreen.withOpacity(0.15) 
                                  : AppColors.borderGray,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: _isOnline ? AppColors.successGreen : AppColors.silverMid,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isOnline ? AppColors.successGreen : AppColors.silverMid,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isOnline ? 'ONLINE' : 'OFFLINE',
                                  style: AppTextStyles.labelBold.copyWith(
                                    color: _isOnline ? AppColors.successGreen : AppColors.silverMid,
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

                // Persistent bottom sheet
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.55,
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

                        // Bottom sheet content
                        Expanded(
                          child: _buildBottomSheetContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomSheetContent() {
    // If online and has active session, navigate to active session screen
    if (_isOnline && _currentRoute != null) {
      // Navigate to active session after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActiveSessionScreen(ride: _currentRoute),
          ),
        );
      });
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pureWhite),
      );
    }

    // If offline
    if (!_isOnline) {
      return _buildOfflineContent();
    }

    // If online but no route
    if (_currentRoute == null) {
      return _buildNoRouteContent();
    }

    // If online with route but not started
    return _buildRouteReadyContent();
  }

  Widget _buildOfflineContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOU\'RE OFFLINE',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Start driving to earn today',
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 8),
          Text(
            'Turn on your status and create a route to start receiving ride requests.',
            style: AppTextStyles.bodyM,
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: 'Go Online',
            icon: Icons.online_prediction,
            onPressed: _toggleOnlineStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildNoRouteContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOU\'RE ONLINE',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.successGreen,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create a route to start',
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 8),
          Text(
            'Set your pickup, destination, and schedule to receive passenger requests.',
            style: AppTextStyles.bodyM,
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: 'Create New Route',
            icon: Icons.add_location_alt,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreateRouteScreen()),
              ).then((_) => _loadDriverStatus());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteReadyContent() {
    final origin = _currentRoute['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = _currentRoute['destination']?.toString().split(',').first ?? 'Unknown';
    final departureTime = _formatTime(_currentRoute['departureTime'] ?? '');
    final availableSeats = _currentRoute['availableSeats'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOUR ROUTE',
            style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 16),
          
          // Route card
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        origin,
                        style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.pureWhite,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        destination,
                        style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.silverMid, size: 16),
                    const SizedBox(width: 6),
                    Text(departureTime, style: AppTextStyles.bodyM),
                    const SizedBox(width: 16),
                    Icon(Icons.event_seat, color: AppColors.silverMid, size: 16),
                    const SizedBox(width: 6),
                    Text('$availableSeats seats', style: AppTextStyles.bodyM),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          CustomButton(
            label: 'Start Session',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ActiveSessionScreen(ride: _currentRoute),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Edit Route',
            variant: CustomButtonVariant.secondary,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateRouteScreen(ride: _currentRoute),
                ),
              ).then((_) => _loadDriverStatus());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineConfirmationSheet() {
    return Container(
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
            Icons.offline_bolt,
            color: AppColors.silverMid,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Go Offline?',
            style: AppTextStyles.headingL,
          ),
          const SizedBox(height: 8),
          Text(
            'You will no longer receive ride requests.',
            style: AppTextStyles.bodyM,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Yes, Go Offline',
            variant: CustomButtonVariant.secondary,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Stay Online',
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    } catch (e) {
      return '';
    }
  }
}
