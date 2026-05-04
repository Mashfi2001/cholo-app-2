import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/ride_card.dart';
import '../../backend_config.dart';
import 'seat_selection_screen.dart';

class RideResultsScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String pickupName;
  final String dropName;
  final String requestedTime;
  final int seats;

  const RideResultsScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.pickupName,
    required this.dropName,
    required this.requestedTime,
    required this.seats,
  });

  @override
  State<RideResultsScreen> createState() => _RideResultsScreenState();
}

class _RideResultsScreenState extends State<RideResultsScreen> {
  List<dynamic> _rides = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSoloSuggestion = false;
  dynamic _soloData;

  @override
  void initState() {
    super.initState();
    _searchRides();
  }

  Future<void> _searchRides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/ride-search/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pickupLat': widget.pickupLat,
          'pickupLng': widget.pickupLng,
          'dropLat': widget.dropLat,
          'dropLng': widget.dropLng,
          'requestedTime': widget.requestedTime,
          'seats': widget.seats,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _rides = data['rides'] ?? [];
          _isSoloSuggestion = data['type'] == 'SOLO_SUGGESTION';
          _soloData = data['soloRide'];
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to search rides';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _requestSoloRide() {
    // For now, we'll show a success message or navigate to a specialized request screen.
    // In a real app, this would call a 'POST /api/ride-requests' endpoint.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Solo ride requested! Drivers will be notified.',
          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
        ),
        backgroundColor: AppColors.successGreen,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _navigateToSeatSelection(dynamic ride) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          rideId: ride['id'],
          ride: ride,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Rides',
                      style: AppTextStyles.headingM,
                    ),
                  ],
                ),
              ),
            ),

            // Results count
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _isLoading
                    ? null
                    : Text(
                        '${_rides.length} ride${_rides.length != 1 ? 's' : ''} found',
                        style: AppTextStyles.bodyM,
                      ),
              ),
            ),

            // Loading or empty state
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.pureWhite,
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.dangerRed,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: AppTextStyles.bodyM,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _searchRides,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pureWhite,
                          foregroundColor: AppColors.primaryBlack,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_rides.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSoloSuggestion ? Icons.person_outline : Icons.search_off,
                        color: AppColors.silverMid,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSoloSuggestion ? 'No Shared Rides Found' : 'No rides found',
                        style: AppTextStyles.headingL,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _isSoloSuggestion 
                            ? 'Would you like to request a solo ride for this route?' 
                            : 'Try a different date or time',
                          style: AppTextStyles.bodyM,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_isSoloSuggestion) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: ElevatedButton(
                            onPressed: _requestSoloRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pureWhite,
                              foregroundColor: AppColors.primaryBlack,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Request Solo Ride'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              // Ride list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ride = _rides[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RideCard(
                          ride: ride,
                          onTap: () => _navigateToSeatSelection(ride),
                        ),
                      );
                    },
                    childCount: _rides.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
