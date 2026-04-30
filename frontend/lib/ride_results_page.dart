import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'ride_details_page.dart';

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
    final rideType = result['type'];
    
    // Debug: Print what we're receiving
    if (result['rides'] != null) {
      for (var ride in result['rides']) {
        print('DEBUG RIDE: id=${ride['id']}, departureTime=${ride['departureTime']}, requestedTime=${ride['requestedTime']}');
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF98825),
        title: const Text(
          'Available Rides',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message Section
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFF98825).withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    rideType == "MATCH"
                        ? Icons.check_circle
                        : Icons.directions_car,
                    color: const Color(0xFFF98825),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result['message'] ?? 'Search results',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rides List or Solo Option
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

  // Build list of available rides (STRICT or NEARBY)
  Widget _buildRidesList(BuildContext context, dynamic result) {
    final rides = result['rides'] as List<dynamic>;

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
            const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(12),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return _buildRideCard(context, ride, index + 1);
      },
    );
  }

  // Build individual ride card - clickable to show details
  Widget _buildRideCard(BuildContext context, dynamic ride, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RideDetailsPage(
              ride: ride,
              pickupLocation: widget.pickupLocation,
              destinationLocation: widget.destinationLocation,
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFF98825).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride Number / Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ride #${ride['id'].toString().substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF98825),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${ride['seats']} seats',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Pickup Location
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${ride['origin']['lat'].toStringAsFixed(4)}, ${ride['origin']['lng'].toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (ride['meta'] != null)
                            Text(
                              '${ride['meta']['pickupDistance']}m away',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Destination Location
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destination',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${ride['destination']['lat'].toStringAsFixed(4)}, ${ride['destination']['lng'].toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (ride['meta'] != null)
                            Text(
                              '${ride['meta']['dropDistance']}m away',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Passenger Request Time
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Requested: ${_formatTime(ride['requestedTime'])}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tap to see details hint
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tap to view details →',
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
      ),
    );
  }

  // Build solo ride suggestion
  Widget _buildSoloSuggestion(BuildContext context, dynamic result) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF98825).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.directions_car,
                size: 50,
                color: Color(0xFFF98825),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Rides Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No drivers are currently traveling to your destination.\nConsider modifying your search or book a private ride.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Book Private Ride Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 32,
                    color: Color(0xFFF98825),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Option 1: Book a Private Ride',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get your own dedicated ride for your exact route',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _bookPrivateRide(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF98825),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
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
            const SizedBox(height: 16),
            // Modify Search Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.search,
                    size: 32,
                    color: Color(0xFFF98825),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Option 2: Modify Your Search',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Change location, time, or date to find shared rides',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF98825), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
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
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _bookPrivateRide(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking your private ride...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement actual private ride booking logic
  }
}
