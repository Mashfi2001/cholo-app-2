import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'nearby_ride_details_page.dart';

class RideResultsPage extends StatefulWidget {
  final dynamic searchResult;
  final LatLng pickupLocation;
  final LatLng destinationLocation;

  const RideResultsPage({
    Key? key,
    required this.searchResult,
    required this.pickupLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  State<RideResultsPage> createState() => _RideResultsPageState();
}

class _RideResultsPageState extends State<RideResultsPage> {
  @override
  Widget build(BuildContext context) {
    final result = widget.searchResult;
    final rideType = result['type'] ?? 'SOLO_SUGGESTION';
    
    if (result['rides'] != null) {
      for (var ride in result['rides']) {
        print('DEBUG RIDE: id=${ride['id']}, departureTime=${ride['departureTime']}, requestedTime=${ride['requestedTime']}');
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF98825),
        title: Text(
          'Available Rides',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Color(0xFFF98825).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    rideType == "MATCH" ? Icons.check_circle : Icons.directions_car,
                    color: Color(0xFFF98825),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Search results',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rideType == "SOLO_SUGGESTION"
                  ? _buildSoloSuggestion(context, result)
                  : _buildRidesList(context, result),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(BuildContext context, dynamic result) {
    final rides = result['rides'] as List<dynamic>? ?? [];

    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[300],
            ),
            SizedBox(height: 16),
            Text(
              'No rides available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _buildRideCard(context, ride);
      },
    );
  }

  Widget _buildRideCard(BuildContext context, dynamic ride) {
    // Safely extract ride data with defaults
    final rideId = ride['id'] ?? 'Unknown';
    final driverName = ride['driver']?['name'] ?? 'Driver';
    final driverId = ride['driver']?['id'] ?? 'N/A';
    final seats = ride['seats'] ?? 0;
    final eta = ride['eta'] ?? ride['departureTime'] ?? '';
    final departureTime = ride['departureTime'] ?? '';
    
    // Safely extract marker data - now includes names
    final pickupLat = ride['pickupMarker']?['lat'] ?? 0.0;
    final pickupLng = ride['pickupMarker']?['lng'] ?? 0.0;
    final pickupName = ride['pickupMarker']?['name'] ?? 'Unknown Location';
    
    final dropLat = ride['dropMarker']?['lat'] ?? 0.0;
    final dropLng = ride['dropMarker']?['lng'] ?? 0.0;
    final dropName = ride['dropMarker']?['name'] ?? 'Unknown Location';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NearbyRideDetailsPage(
              ride: ride,
              pickupLocation: widget.pickupLocation,
              destinationLocation: widget.destinationLocation,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Driver Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride #$rideId',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF98825),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Driver: $driverName',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Driver ID: $driverId',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$seats seats',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // ETA
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.blue[700]),
                    SizedBox(width: 8),
                    Text(
                      'ETA: ${_formatTime(eta)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              // Pickup Location - now shows name
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Pickup',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          pickupName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('View Slots - Coming Soon'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'View Slots →',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Dropoff Location - now shows name
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Dropoff',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          dropName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Times
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Departure: ${_formatTime(departureTime)}',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Tap hint
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to view route map →',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Solo suggestion
  Widget _buildSoloSuggestion(BuildContext context, dynamic result) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF98825).withOpacity(0.1),
              ),
              child: Icon(
                Icons.directions_car,
                size: 50,
                color: Color(0xFFF98825),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Rides Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'No drivers are currently traveling to your destination.\\nConsider modifying your search or book a private ride.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            // Book Private Ride
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 32,
                    color: Color(0xFFF98825),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Option 1: Book a Private Ride',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get your own dedicated ride for your exact route',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _bookPrivateRide(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF98825),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Book Private Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Modify Search
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search,
                    size: 32,
                    color: Color(0xFFF98825),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Option 2: Modify Your Search',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Change location, time, or date to find shared rides',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFFF98825), width: 2),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Modify Search',
                        style: TextStyle(
                          color: Color(0xFFF98825),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _bookPrivateRide(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking your private ride...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

