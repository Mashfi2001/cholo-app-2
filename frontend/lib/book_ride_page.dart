import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  final String openRouteServiceApiKey =
      "your_api_key"; // Ensure this is replaced with your actual API key

  Future<void> fetchRouteDetails() async {
    if (pickupLocation == null || destinationLocation == null) return;

    setState(() => isSearching = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$openRouteServiceApiKey&start=${pickupLocation!.longitude},${pickupLocation!.latitude}&end=${destinationLocation!.longitude},${destinationLocation!.latitude}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle route response here, display it if needed
      }
    } catch (e) {
      print('Route fetching error: $e');
    } finally {
      setState(() => isSearching = false);
    }
  }

  Future<void> searchRide() async {
    // You can call your backend API to search for available rides
    // Based on the selected pickup and destination locations
    // For now, let's just print the selected details
    print('Searching for ride...');
    print('Pickup: ${pickupController.text}');
    print('Destination: ${destinationController.text}');
    print('Time: ${timeController.text}');
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
          'https://api.openrouteservice.org/geocode/reverse?api_key=$openRouteServiceApiKey&point.lon=${point.longitude}&point.lat=${point.latitude}&size=1',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          return data['features'][0]['properties']['label'] ??
              'Unknown location';
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    onTap: () {
                      // Handle pickup location tap
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Select Destination Location',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () {
                      // Handle destination location tap
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Select Departure Time',
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
                          setState(() {
                            timeController.text =
                                '${pickedDate.toLocal()} ${pickedTime.format(context)}';
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