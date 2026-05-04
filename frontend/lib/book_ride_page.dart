import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'backend_config.dart';
import 'ride_search_loading_page.dart';
import 'screens/passenger/location_search_page.dart';

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

  List<LatLng> routePoints = []; 
  List<Map<String, dynamic>> originSearchResults = [];
  List<Map<String, dynamic>> destinationSearchResults = [];
  bool isInlineSearching = false;

  final String openRouteServiceApiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImU0YzRiNTY2MGNjMjRmYjI5ZjE3ZTFiMGFmMGNiZWUzIiwiaCI6Im11cm11cjY0In0=";

  // Fetch route details using OSRM
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

  Future<void> searchLocations(String query, bool isOrigin) async {
    if (query.length < 3) {
      setState(() => isOrigin ? originSearchResults = [] : destinationSearchResults = []);
      return;
    }
    setState(() => isInlineSearching = true);
    try {
      final response = await http.get(Uri.parse(
          'https://api.openrouteservice.org/geocode/search?api_key=$openRouteServiceApiKey&text=$query&focus.point.lon=90.4125&focus.point.lat=23.8103&size=5'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['features'].map((f) => {
              'label': f['properties']['label'],
              'lat': f['geometry']['coordinates'][1],
              'lon': f['geometry']['coordinates'][0],
            }));
        setState(() => isOrigin ? originSearchResults = results : destinationSearchResults = results);
      }
    } catch (_) {
    } finally {
      setState(() => isInlineSearching = false);
    }
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results, bool isOrigin) {
    if (results.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final r = results[index];
          return ListTile(
            leading: const Icon(Icons.location_on, size: 18, color: Color(0xFFF98825)),
            title: Text(r['label'], style: const TextStyle(fontSize: 13)),
            onTap: () {
              setState(() {
                if (isOrigin) {
                  pickupLocation = LatLng(r['lat'], r['lon']);
                  pickupController.text = r['label'];
                  originSearchResults = [];
                  mapController.move(pickupLocation!, 14);
                } else {
                  destinationLocation = LatLng(r['lat'], r['lon']);
                  destinationController.text = r['label'];
                  destinationSearchResults = [];
                  mapController.move(destinationLocation!, 14);
                }
              });
              if (pickupLocation != null && destinationLocation != null) fetchRouteDetails();
            },
          );
        },
      ),
    );
  }

  Future<void> searchRide() async {
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
      final parts = timeController.text.split(' ');
      if (parts.length < 3) throw Exception('Invalid time format');
      
      String dateStr = parts[0]; 
      String timeStr = parts[1]; 
      String meridiem = parts[2]; 
      
      final timeParts = timeStr.split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      
      if (meridiem == 'PM' && hour != 12) {
        hour += 12;
      } else if (meridiem == 'AM' && hour == 12) {
        hour = 0;
      }
      
      final selectedDate = DateTime.parse(dateStr);
      DateTime selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        hour,
        minute,
      );

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  Future<void> handleMapTap(LatLng point) async {
    if (pickupLocation == null) {
      setState(() {
        pickupLocation = point;
        pickupController.text = "Loading pickup location...";
      });
      String locationName = await reverseGeocode(point);
      setState(() => pickupController.text = locationName);
    } else if (destinationLocation == null) {
      setState(() {
        destinationLocation = point;
        destinationController.text = "Loading destination...";
      });
      String locationName = await reverseGeocode(point);
      setState(() => destinationController.text = locationName);
      if (pickupLocation != null && destinationLocation != null) await fetchRouteDetails();
    } else {
      setState(() {
        pickupLocation = null;
        destinationLocation = null;
        pickupController.clear();
        destinationController.clear();
        routePoints = [];
      });
    }
  }

  Future<String> reverseGeocode(LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}'),
        headers: {'User-Agent': 'ChaloApp'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
          return address['road'] ?? address['suburb'] ?? address['city'] ?? address['town'] ?? address['county'] ?? 'Unknown location';
        }
        if (data['display_name'] != null) return data['display_name'];
      }
    } catch (_) {}
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
                  initialCenter: const LatLng(23.8103, 90.4125),
                  initialZoom: 12,
                  onTap: (tapPosition, point) => handleMapTap(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yourapp.passenger',
                  ),
                  if (pickupLocation != null)
                    MarkerLayer(markers: [Marker(point: pickupLocation!, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.green, size: 40))]),
                  if (destinationLocation != null)
                    MarkerLayer(markers: [Marker(point: destinationLocation!, width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40))]),
                  if (routePoints.isNotEmpty)
                    PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 4.0, color: Colors.blue)]),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pickupController,
                      onChanged: (v) => searchLocations(v, true),
                      decoration: InputDecoration(
                        labelText: 'Select Pickup Location',
                        border: const OutlineInputBorder(),
                        suffixIcon: isInlineSearching && pickupController.text.length >= 3 
                            ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) 
                            : null,
                      ),
                    ),
                    _buildSearchResults(originSearchResults, true),
                    const SizedBox(height: 8),
                    TextField(
                      controller: destinationController,
                      onChanged: (v) => searchLocations(v, false),
                      decoration: InputDecoration(
                        labelText: 'Select Destination Location',
                        border: const OutlineInputBorder(),
                        suffixIcon: isInlineSearching && destinationController.text.length >= 3 
                            ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))) 
                            : null,
                      ),
                    ),
                    _buildSearchResults(destinationSearchResults, false),
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
                        final pickedDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (pickedTime != null) {
                            final formattedDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                            final formattedTime = pickedTime.format(context);
                            setState(() => timeController.text = '$formattedDate $formattedTime');
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSearching ? null : searchRide,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF98825), minimumSize: const Size(double.infinity, 50)),
                      child: isSearching ? const CircularProgressIndicator(color: Colors.white) : const Text('Search Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}