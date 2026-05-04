import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';
import 'passenger_list_screen.dart';
import 'passenger_request_card.dart';

class ActiveSessionScreen extends StatefulWidget {
  final dynamic ride;

  const ActiveSessionScreen({super.key, required this.ride});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  List<dynamic> _pendingRequests = [];
  List<dynamic> _confirmedPassengers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadSessionData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _loadSessionData() async {
    try {
      // Load pending requests
      final requestsResponse = await http.get(
        Uri.parse('$backendUrl/api/rides/${widget.ride['id']}/pending-requests'),
      );

      if (requestsResponse.statusCode == 200) {
        final data = jsonDecode(requestsResponse.body);
        setState(() {
          _pendingRequests = data['requests'] ?? [];
        });
      }

      // Load confirmed passengers
      final passengersResponse = await http.get(
        Uri.parse('$backendUrl/api/rides/${widget.ride['id']}/passengers'),
      );

      if (passengersResponse.statusCode == 200) {
        final data = jsonDecode(passengersResponse.body);
        setState(() {
          _confirmedPassengers = data['passengers'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading session data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequest(dynamic request, bool accept) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/bookings/${request['id']}/respond'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': Session.userId,
          'accept': accept,
        }),
      );

      if (response.statusCode == 200) {
        // Animate card out
        setState(() {
          _pendingRequests.remove(request);
          if (accept) {
            _confirmedPassengers.add(request);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept ? 'Request accepted' : 'Request rejected',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: accept ? AppColors.successGreen : AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      print('Error handling request: $e');
    }
  }

  Future<void> _completeRide() async {
    final confirm = await showModalBottomSheet<bool>(
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
              Icons.check_circle,
              color: AppColors.successGreen,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Complete Ride?',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'This will end the session and mark the ride as completed.',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Yes, Complete',
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Cancel',
              variant: CustomButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/rides/${widget.ride['id']}/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driverId': Session.userId}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ride completed!',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error completing ride: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final origin = widget.ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = widget.ride['destination']?.toString().split(',').first ?? 'Unknown';
    final totalSeats = widget.ride['totalSeats'] ?? 6;
    final filledSeats = _confirmedPassengers.fold<int>(
      0, (sum, p) => sum + (p['seats'] as int? ?? 1),
    );

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // Map
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(23.8103, 90.4125),
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

          // Top overlay
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Session Active',
                                style: AppTextStyles.headingL.copyWith(fontSize: 20),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.cardBlack,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _formatDuration(_elapsed),
                                style: AppTextStyles.bodyM.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Status card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.successGreen),
                          ),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.successGreen,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      '$filledSeats/$totalSeats seats',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.pureWhite,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                      onPressed: () => Navigator.pop(context),
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
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pending requests header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'BOOKING REQUESTS',
                              style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
                            ),
                            if (_pendingRequests.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warningAmber,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${_pendingRequests.length}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryBlack,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pending requests list
                    if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.pureWhite),
                      )
                    else if (_pendingRequests.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox, color: AppColors.silverMid, size: 48),
                            const SizedBox(height: 12),
                            Text('No pending requests', style: AppTextStyles.bodyM),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _pendingRequests.length,
                          itemBuilder: (context, index) {
                            final request = _pendingRequests[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PassengerRequestCard(
                                request: request,
                                onAccept: () => _handleRequest(request, true),
                                onReject: () => _handleRequest(request, false),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Bottom actions
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            label: 'Passengers',
                            variant: CustomButtonVariant.secondary,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PassengerListScreen(
                                    ride: widget.ride,
                                    confirmedPassengers: _confirmedPassengers,
                                    pendingRequests: _pendingRequests,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            label: 'Complete',
                            onPressed: _completeRide,
                          ),
                        ),
                      ],
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
}
