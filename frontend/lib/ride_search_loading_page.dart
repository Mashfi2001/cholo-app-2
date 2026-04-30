import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'backend_config.dart';
import 'ride_results_page.dart';

class RideSearchLoadingPage extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final String requestedTime;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final String pickupName;
  final String dropName;

  const RideSearchLoadingPage({
    Key? key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.requestedTime,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.pickupName,
    required this.dropName,
  }) : super(key: key);

  @override
  State<RideSearchLoadingPage> createState() => _RideSearchLoadingPageState();
}

class _RideSearchLoadingPageState extends State<RideSearchLoadingPage> {
  late Future<void> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = _performSearch();
  }

  Future<void> _performSearch() async {
    try {
      final response = await http.post(
Uri.parse('${backendUrl}/api/ride-search/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pickupLat': widget.pickupLat,
          'pickupLng': widget.pickupLng,
          'dropLat': widget.dropLat,
          'dropLng': widget.dropLng,
          'pickupName': widget.pickupName,
          'dropName': widget.dropName,
          'requestedTime': widget.requestedTime,
          'debug': true,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RideResultsPage(
                searchResult: result,
                pickupLocation: widget.pickupLocation,
                destinationLocation: widget.destinationLocation,
              ),
            ),
          );
        }
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        body: FutureBuilder<void>(
          future: _searchFuture,
          builder: (context, snapshot) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF98825),
                    Color(0xFFFF6B6B),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 8,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Searching for Rides',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Finding the best matches for you...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
