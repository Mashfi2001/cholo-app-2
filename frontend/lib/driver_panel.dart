import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'backend_config.dart';
import 'login_screen.dart';
import 'verification_request_page.dart';
import 'my_rides_page_driver.dart';
import 'ride_details_page.dart';
import 'ride_summary_page.dart';
import 'session.dart';
import 'broadcast_banner.dart';

class DriverPanel extends StatefulWidget {
  final int userId;
  final String userName;

  const DriverPanel({Key? key, required this.userId, required this.userName})
    : super(key: key);

  @override
  State<DriverPanel> createState() => _DriverPanelState();
}

class _DriverPanelState extends State<DriverPanel> {
  // State from old DriverPanel
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController departureController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();

  int? rideId;
  String rideStatus = "NOT_CREATED";
  bool isLoading = false;
  DateTime? selectedDepartureTime;
  List<LatLng> routePoints = [];
  double? routeDistanceKm;
  double? routeDurationMin;
  List<Map<String, dynamic>> originSearchResults = [];
  List<Map<String, dynamic>> destinationSearchResults = [];
  bool isSearching = false;
  bool isSelectingOrigin = false;
  bool isSelectingDestination = false;
  final MapController mapController = MapController();

  LatLng? startLocation;
  LatLng? endLocation;

  final String openRouteServiceApiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImU0YzRiNTY2MGNjMjRmYjI5ZjE3ZTFiMGFmMGNiZWUzIiwiaCI6Im11cm11cjY0In0=";

  int minEstimatedFare = 0;
  int maxEstimatedFare = 0;
  bool isFareEstimateLoading = false;

  // State from new Dashboard
  List<dynamic> notifications = [];
  List<dynamic> pendingSeatRequests = [];
  Map<String, dynamic>? userData;

  bool get canEdit => rideStatus == "NOT_CREATED" || rideStatus == "PLANNED";

  @override
  void initState() {
    super.initState();
    seatsController.text = "4";
    fetchData();
  }

  Future<void> fetchData() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final driverId = widget.userId;
      
      // 1. Notifications
      final notifRes = await http.get(Uri.parse('$backendUrl/api/notifications/user/$driverId'));
      if (notifRes.statusCode == 200) {
        notifications = jsonDecode(notifRes.body)['notifications'] ?? [];
      }

      // 2. Pending Requests
      final pendingRes = await http.get(Uri.parse('$backendUrl/seat-booking/driver/$driverId/requests'));
      if (pendingRes.statusCode == 200) {
        pendingSeatRequests = jsonDecode(pendingRes.body)['requests'] ?? [];
      }

      // 3. User History (Warnings)
      final userRes = await http.get(Uri.parse('$backendUrl/api/complaints/passenger/$driverId/history'));
      if (userRes.statusCode == 200) {
        userData = jsonDecode(userRes.body);
      }

      // 4. Current Ride (check if driver has an active ride)
      final activeRideRes = await http.get(Uri.parse('$backendUrl/api/rides/driver/$driverId/active'));
      if (activeRideRes.statusCode == 200) {
        final rideData = jsonDecode(activeRideRes.body)['ride'];
        if (rideData != null) {
          rideId = rideData['id'];
          rideStatus = rideData['status'];
          originController.text = rideData['origin'];
          destinationController.text = rideData['destination'];
          departureController.text = rideData['departureTime'];
          seatsController.text = rideData['seats'].toString();
          routeDistanceKm = (rideData['routeDistanceKm'] as num?)?.toDouble();
          routeDurationMin = (rideData['routeDurationMin'] as num?)?.toDouble();
          
          if (rideData['originLat'] != null && rideData['originLng'] != null) {
            startLocation = LatLng(rideData['originLat'], rideData['originLng']);
          }
          if (rideData['destinationLat'] != null && rideData['destinationLng'] != null) {
            endLocation = LatLng(rideData['destinationLat'], rideData['destinationLng']);
          }
          // Note: we might want to fetch route points here if we had them saved, or just leave it blank for now.
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- Logic Helpers ---

  Future<void> _fetchFareEstimatesFromBackend() async {
    if (routeDistanceKm == null) return;
    final seatCount = int.tryParse(seatsController.text.trim()) ?? 0;
    if (seatCount <= 0) return;
    setState(() => isFareEstimateLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${backendUrl}/api/fares/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'routeDistanceKm': routeDistanceKm, 'seats': seatCount}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          minEstimatedFare = (data['minFare'] as num).toInt();
          maxEstimatedFare = (data['maxFare'] as num).toInt();
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => isFareEstimateLoading = false);
    }
  }

  Future<void> searchLocations(String query, bool isOrigin) async {
    if (query.isEmpty) {
      setState(() => isOrigin ? originSearchResults = [] : destinationSearchResults = []);
      return;
    }
    setState(() => isSearching = true);
    try {
      final response = await http.get(Uri.parse('https://api.openrouteservice.org/geocode/search?api_key=$openRouteServiceApiKey&text=$query&focus.point.lon=90.4125&focus.point.lat=23.8103'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['features'].map((f) => {
          'label': f['properties']['label'],
          'lat': f['geometry']['coordinates'][1],
          'lon': f['geometry']['coordinates'][0],
        }));
        setState(() => isOrigin ? originSearchResults = results : destinationSearchResults = results);
      }
    } catch (_) {} finally {
      setState(() => isSearching = false);
    }
  }

  Future<void> fetchRealRoute() async {
    if (startLocation == null || endLocation == null) return;
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car?api_key=$openRouteServiceApiKey&start=${startLocation!.longitude},${startLocation!.latitude}&end=${endLocation!.longitude},${endLocation!.latitude}'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['features'][0]['geometry']['coordinates'];
        final summary = data['features'][0]['properties']['summary'];
        setState(() {
          routePoints = coordinates.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          routeDistanceKm = summary['distance'] / 1000;
          routeDurationMin = summary['duration'] / 60;
        });
        await _fetchFareEstimatesFromBackend();
      }
    } catch (_) {} finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> createRide() async {
    if (originController.text.isEmpty || destinationController.text.isEmpty || selectedDepartureTime == null) return;
    setState(() => isLoading = true);
    try {
      final response = await http.post(Uri.parse('$backendUrl/api/rides'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'driverId': widget.userId,
          'origin': originController.text,
          'destination': destinationController.text,
          'originLat': startLocation?.latitude,
          'originLng': startLocation?.longitude,
          'destinationLat': endLocation?.latitude,
          'destinationLng': endLocation?.longitude,
          'routeDistanceKm': routeDistanceKm,
          'routeDurationMin': routeDurationMin,
          'departureTime': selectedDepartureTime!.toIso8601String(),
          'seats': int.tryParse(seatsController.text) ?? 4,
        }),
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride created successfully')));
        Navigator.pop(context); // Take him back to the dashboard
      }
    } catch (_) {} finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> startRide() async {
    try {
      final response = await http.put(Uri.parse('$backendUrl/api/rides/$rideId/start'));
      if (response.statusCode == 200) {
        setState(() => rideStatus = 'ONGOING');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride started')));
      }
    } catch (_) {}
  }

  Future<void> cancelRide() async {
    try {
      final response = await http.put(Uri.parse('$backendUrl/api/rides/$rideId/cancel'));
      if (response.statusCode == 200) {
        setState(() {
          rideId = null;
          rideStatus = 'NOT_CREATED';
          routePoints = [];
          startLocation = null;
          endLocation = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride cancelled')));
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (_) {}
  }

  Future<void> completeRide() async {
    try {
      final response = await http.put(Uri.parse('$backendUrl/api/rides/$rideId/complete'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RideSummaryPage(ride: data['ride'])),
        );
        // Navigator.pushReplacement replaces DriverPanel with RideSummaryPage.
        // When RideSummaryPage is popped, it goes back to Dashboard.
        setState(() {
          rideId = null;
          rideStatus = 'NOT_CREATED';
        });
      }
    } catch (_) {}
  }

  Future<void> _decideSeatRequest(int rId, int pId, String decision) async {
    try {
      await http.post(Uri.parse('$backendUrl/seat-booking/requests/$rId/$pId/decision'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'driverId': widget.userId, 'decision': decision}),
      );
      fetchData();
    } catch (_) {}
  }

  Future<void> deleteNotification(int id) async {
    try {
      await http.delete(Uri.parse('$backendUrl/api/notifications/$id'));
      setState(() => notifications.removeWhere((n) => n['id'] == id));
    } catch (_) {}
  }

  Future<void> selectDepartureTime() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) {
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() {
          selectedDepartureTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          departureController.text = selectedDepartureTime!.toString();
        });
      }
    }
  }

  void handleMapTap(TapPosition pos, LatLng point) async {
    if (!canEdit || isLoading) return;
    setState(() { originSearchResults = []; destinationSearchResults = []; });
    if (startLocation == null) {
      setState(() { startLocation = point; endLocation = null; routePoints = []; originController.text = "Loading..."; });
      final res = await http.get(Uri.parse('https://api.openrouteservice.org/geocode/reverse?api_key=$openRouteServiceApiKey&point.lon=${point.longitude}&point.lat=${point.latitude}&size=1'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => originController.text = data['features'][0]['properties']['label'] ?? "Selected Location");
      }
    } else if (endLocation == null) {
      setState(() { endLocation = point; destinationController.text = "Loading..."; });
      final res = await http.get(Uri.parse('https://api.openrouteservice.org/geocode/reverse?api_key=$openRouteServiceApiKey&point.lon=${point.longitude}&point.lat=${point.latitude}&size=1'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() => destinationController.text = data['features'][0]['properties']['label'] ?? "Selected Location");
        fetchRealRoute();
      }
    } else {
      setState(() { startLocation = point; endLocation = null; routePoints = []; originController.text = "Loading..."; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = const Color(0xFFF98825);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: Text('Logged in as ${widget.userName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: _showNotifications),
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchData),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (userData != null && ((userData!['totalWarnings'] ?? 0) > 0 || userData!['isBanned'] == true))
                _buildStatusAlert(),
              const BroadcastBanner(),
              const SizedBox(height: 16),
              
              // --- Map Section ---
              const Text('Ride Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 300,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(23.8103, 90.4125),
                    initialZoom: 12,
                    onTap: handleMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cholo.app',
                    ),
                    if (startLocation != null) MarkerLayer(markers: [Marker(point: startLocation!, child: const Icon(Icons.location_on, color: Colors.green, size: 30))]),
                    if (endLocation != null) MarkerLayer(markers: [Marker(point: endLocation!, child: const Icon(Icons.location_on, color: Colors.red, size: 30))]),
                    if (routePoints.isNotEmpty) PolylineLayer(polylines: [Polyline(points: routePoints, color: Colors.blue, strokeWidth: 3.0)]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Actions Section ---
              if (rideStatus == "NOT_CREATED") _buildCreationForm(),
              if (rideStatus == "PLANNED") _buildPlannedActions(),
              if (rideStatus == "ONGOING") _buildOngoingActions(),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreationForm() {
    return Column(
      children: [
        TextField(controller: originController, decoration: const InputDecoration(labelText: 'Origin', border: OutlineInputBorder()), onChanged: (v) => searchLocations(v, true)),
        if (originSearchResults.isNotEmpty) _buildSearchResults(originSearchResults, true),
        const SizedBox(height: 12),
        TextField(controller: destinationController, decoration: const InputDecoration(labelText: 'Destination', border: OutlineInputBorder()), onChanged: (v) => searchLocations(v, false)),
        if (destinationSearchResults.isNotEmpty) _buildSearchResults(destinationSearchResults, false),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(controller: departureController, decoration: const InputDecoration(labelText: 'Departure', border: OutlineInputBorder()), readOnly: true, onTap: selectDepartureTime)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: seatsController,
                decoration: const InputDecoration(
                    labelText: 'Seats', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => _fetchFareEstimatesFromBackend(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isFareEstimateLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (minEstimatedFare > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                Text(
                  'Est. minimum total: $minEstimatedFare Taka',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Est. maximum total: $maxEstimatedFare Taka',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ElevatedButton(
          onPressed: isLoading ? null : createRide,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF98825), minimumSize: const Size(double.infinity, 50)),
          child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPlannedActions() {
    return Column(
      children: [
        Text('Active Ride: ${originController.text} to ${destinationController.text}', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ElevatedButton(onPressed: startRide, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Start Ride', style: TextStyle(color: Colors.white)))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: cancelRide, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Cancel Ride', style: TextStyle(color: Colors.white)))),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RideDetailsPage(ride: {'id': rideId, 'origin': originController.text, 'destination': destinationController.text, 'status': rideStatus, 'driverId': widget.userId}))),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)),
          child: const Text('View Ride & Passenger Details', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildOngoingActions() {
    return Column(
      children: [
        const Text('Ride in Progress', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: completeRide, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 50)), child: const Text('End Ride', style: TextStyle(color: Colors.white))),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RideDetailsPage(ride: {'id': rideId, 'origin': originController.text, 'destination': destinationController.text, 'status': rideStatus, 'driverId': widget.userId}))), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, minimumSize: const Size(double.infinity, 50)), child: const Text('View Live Ride Details', style: TextStyle(color: Colors.white))),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF98825), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
      child: Column(children: [Icon(icon, size: 24), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> results, bool isOrigin) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: ListView.builder(shrinkWrap: true, itemCount: results.length, itemBuilder: (context, index) {
        final r = results[index];
        return ListTile(title: Text(r['label'], style: const TextStyle(fontSize: 12)), onTap: () {
          setState(() {
            if (isOrigin) { startLocation = LatLng(r['lat'], r['lon']); originController.text = r['label']; originSearchResults = []; }
            else { endLocation = LatLng(r['lat'], r['lon']); destinationController.text = r['label']; destinationSearchResults = []; }
          });
          if (startLocation != null && endLocation != null) fetchRealRoute();
        });
      }),
    );
  }

  void _showNotifications() {
    showDialog(context: context, builder: (context) => AlertDialog(title: const Text('Notifications'), content: SizedBox(width: double.maxFinite, child: ListView(shrinkWrap: true, children: [
      if (pendingSeatRequests.isNotEmpty) ...[const Text('Requests', style: TextStyle(fontWeight: FontWeight.bold)), ...pendingSeatRequests.map((r) => ListTile(title: Text(r['passengerName']), subtitle: Text('${r['origin']} to ${r['destination']}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _decideSeatRequest(r['rideId'], r['passengerId'], 'ACCEPT')),
        IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _decideSeatRequest(r['rideId'], r['passengerId'], 'REJECT')),
      ])))],
      ...notifications.map((n) => ListTile(title: Text(n['title']), subtitle: Text(n['message']), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => deleteNotification(n['id'])))),
    ])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]));
  }

  Widget _buildStatusAlert() {
    final bool isBanned = userData?['isBanned'] ?? false;
    final int warnings = userData?['totalWarnings'] ?? 0;
    return Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: isBanned ? Colors.red.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: isBanned ? Colors.red : Colors.orange)), child: Row(children: [Icon(isBanned ? Icons.block : Icons.warning, color: isBanned ? Colors.red : Colors.orange), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(isBanned ? 'BANNED' : 'WARNING', style: TextStyle(fontWeight: FontWeight.bold, color: isBanned ? Colors.red : Colors.orange.shade900)), Text(isBanned ? 'Account suspended.' : 'You have $warnings warnings.', style: const TextStyle(fontSize: 11))]))]));
  }
}
