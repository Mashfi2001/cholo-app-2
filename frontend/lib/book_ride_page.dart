import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'backend_config.dart';
import 'ride_search_loading_page.dart';

class BookRidePage extends StatefulWidget {
  const BookRidePage({Key? key}) : super(key: key);

  @override
  State<BookRidePage> createState() => _BookRidePageState();
}

class _BookRidePageState extends State<BookRidePage> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  bool isSearching = false;
  final MapController mapController = MapController();
  LatLng? pickupLocation;
  LatLng? destinationLocation;

  List<LatLng> routePoints = []; // To hold the polyline points

  // Fetch route details using OSRM (Open Source Routing Machine)
  Future<void> fetchRouteDetails() async {
    if (pickupLocation == null || destinationLocation == null) return;

    setState(() => isSearching = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${pickupLocation!.longitude},${pickupLocation!.latitude};${destinationLocation!.longitude},${destinationLocation!.latitude}?overview=full&geometries=geojson',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          var coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            routePoints = coordinates
                .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Route fetching error: $e');
    } finally {
      setState(() => isSearching = false);
    }
  }

  Future<void> searchRide() async {
    // Validate that all fields are filled
    if (pickupLocation == null || destinationLocation == null || timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup, destination, and time'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Parse the datetime string
      // Format is now: "2026-04-25 6:20 PM"
      final parts = timeController.text.split(' ');
      
      if (parts.length < 3) {
        throw Exception('Invalid time format');
      }
      
      String dateStr = parts[0]; // 2026-04-25
      String timeStr = parts[1]; // 6:20
      String meridiem = parts[2]; // PM
      
      // Parse time string (6:20)
      final timeParts = timeStr.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      
      // Convert to 24-hour format
      if (meridiem == 'PM' && hour != 12) {
        hour += 12;
      } else if (meridiem == 'AM' && hour == 12) {
        hour = 0;
      }
      
      // Create the datetime
      final selectedDate = DateTime.parse(dateStr);
      DateTime selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
        minute,
      );

      print('DEBUG: Parsed time -> $selectedDateTime');
      print('DEBUG: Pickup (${pickupLocation!.latitude}, ${pickupLocation!.longitude})');
      print('DEBUG: Drop (${destinationLocation!.latitude}, ${destinationLocation!.longitude})');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideSearchLoadingPage(
              pickupLat: pickupLocation!.latitude,
              pickupLng: pickupLocation!.longitude,
              dropLat: destinationLocation!.latitude,
              dropLng: destinationLocation!.longitude,
              pickupName: pickupController.text,
              dropName: destinationController.text,
              requestedTime: selectedDateTime.toIso8601String(),
              pickupLocation: pickupLocation!,
              destinationLocation: destinationLocation!,
            ),
          ),
        );
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // This function handles map tap
  Future<void> handleMapTap(LatLng point) async {
    if (pickupLocation == null) {
      // First tap: Set pickup location
      setState(() {
        pickupLocation = point;
        pickupController.text = "Loading pickup location...";
      });

      // Fetch the location name from reverse geocoding
      String locationName = await reverseGeocode(point);
      setState(() {
        pickupController.text = locationName; // Update pickup location text
      });
    } else if (destinationLocation == null) {
      // Second tap: Set destination location
      setState(() {
        destinationLocation = point;
        destinationController.text = "Loading destination...";
      });

      // Fetch the location name from reverse geocoding
      String locationName = await reverseGeocode(point);
      setState(() {
        destinationController.text = locationName; // Update destination location text
      });

      // Fetch route details if both locations are set
      if (pickupLocation != null && destinationLocation != null) {
        await fetchRouteDetails();
      }
    } else {
      // Third tap: Reset both pickup and destination
      setState(() {
        pickupLocation = null;
        destinationLocation = null;
        pickupController.clear();
        destinationController.clear();
      });
    }
  }

  Future<String> reverseGeocode(LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}',
        ),
        headers: {
          'User-Agent': 'ChaloApp',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          // Try to get a meaningful location name from address components
          final address = data['address'];
          final locationName = address['road'] ?? 
              address['suburb'] ?? 
              address['city'] ?? 
              address['town'] ?? 
              address['county'] ?? 
              'Unknown location';
          return locationName;
        }
        // Fallback to display_name if available
        if (data['display_name'] != null) {
          return data['display_name'];
        }
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }

    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF98825),
        title: const Text(
          'Passenger Ride Selection',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: const LatLng(23.8103, 90.4125), // Dhaka
                  initialZoom: 12,
                  onTap: (tapPosition, point) {
                    handleMapTap(point); // Call handleMapTap when map is tapped
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yourapp.passenger',
                  ),
                  if (pickupLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: pickupLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  if (destinationLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: destinationLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  if (routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,  // Use the fetched route points
                          strokeWidth: 4.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Select Pickup Location',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Select Destination Location',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Select Request Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          // Format as: "2026-04-25 6:20 PM" for clearer display
                          final formattedDate =
                              '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                          final formattedTime = pickedTime.format(context);
                          setState(() {
                            timeController.text = '$formattedDate $formattedTime';
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSearching ? null : searchRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF98825),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: isSearching
                        ? const CircularProgressIndicator()
                        : const Text('Search Ride'),
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