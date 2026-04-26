import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login_screen.dart';
import 'verification_request_page.dart';
import 'book_ride_page.dart';
import 'broadcast_banner.dart';
import 'SeatSelectionPage.dart';
import 'session.dart';
import 'backend_config.dart';
import 'passenger_rides_list.dart';

class UserPanel extends StatefulWidget {
  final int userId;
  final String userName;

  const UserPanel({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserPanel> createState() => _UserPanelState();
}

class _UserPanelState extends State<UserPanel> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (Session.userId == null) return;

    setState(() => isLoading = true);
    try {
      final notifRes = await http.get(
        Uri.parse('$backendUrl/api/notifications/user/${Session.userId}'),
      );

      final userRes = await http.get(
        Uri.parse(
          '$backendUrl/api/complaints/passenger/${Session.userId}/history',
        ),
      );

      if (notifRes.statusCode == 200 && userRes.statusCode == 200) {
        final notifBody = jsonDecode(notifRes.body);
        setState(() {
          notifications = List<dynamic>.from(notifBody['notifications'] ?? []);
          userData = jsonDecode(userRes.body) as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color brandOrange = const Color(0xFFF98825);
    final Color darkText = const Color(0xFF2C323A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text(
          'User Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (userData != null &&
                        ((userData!['totalWarnings'] ?? 0) > 0 ||
                            userData!['isBanned'] == true)) ...[
                      _buildStatusAlert(),
                      const SizedBox(height: 20),
                    ],
                    if (notifications.isNotEmpty) ...[
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...notifications
                          .take(3)
                          .map((n) => _buildNotificationCard(n)),
                      if (notifications.length > 3)
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All Notifications'),
                        ),
                      const SizedBox(height: 20),
                    ],
                    const BroadcastBanner(),
                    const SizedBox(height: 24),
                    Image.asset('assets/cholo_logo.png', height: 80),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to Cholo, ${widget.userName}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Find and book rides with ease',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildFeatureSection(brandOrange, darkText),
                    const SizedBox(height: 32),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C323A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Book Ride',
                            Icons.directions_car,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const BookRidePage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            'My Rides',
                            Icons.history,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PassengerRidesList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Book Seat',
                            Icons.event_seat,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SeatSelectionPage(rideId: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Profile',
                            Icons.person,
                            () {},
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            'Logout',
                            Icons.logout,
                            () {
                              Session.userId = null;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            'Verify Profile',
                            Icons.verified_user,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VerificationRequestPage(
                                    userId: widget.userId,
                                    userName: widget.userName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            'Support',
                            Icons.help,
                            () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusAlert() {
    final bool isBanned = userData?['isBanned'] ?? false;
    final int warnings = userData?['totalWarnings'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isBanned ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBanned ? Colors.red : Colors.orange),
      ),
      child: Row(
        children: [
          Icon(
            isBanned ? Icons.block : Icons.warning_amber_rounded,
            color: isBanned ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isBanned ? 'ACCOUNT BANNED' : 'ACCOUNT WARNING',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isBanned ? Colors.red : Colors.orange.shade900,
                  ),
                ),
                Text(
                  isBanned
                      ? 'Your account has been suspended due to violations.'
                      : 'You have $warnings warning(s). Please follow platform rules.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic n) {
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    if (n['type'] == 'WARNING') {
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
    } else if (n['type'] == 'DANGER') {
      icon = Icons.error_outline;
      color = Colors.red;
    } else if (n['type'] == 'SUCCESS') {
      icon = Icons.check_circle_outline;
      color = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          n['title'].toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          n['message'].toString(),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          n['createdAt'].toString().length > 10
              ? n['createdAt'].toString().substring(5, 10)
              : '',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildFeatureSection(Color brandOrange, Color darkText) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandOrange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            'Book a Ride',
            'Find and book rides to your destination',
          ),
          _buildFeatureItem(
            'Ride History',
            'View your past rides and bookings',
          ),
          _buildFeatureItem(
            'Payment Methods',
            'Manage your payment options',
          ),
          _buildFeatureItem(
            'Profile Settings',
            'Update your personal information',
          ),
          _buildFeatureItem(
            'Support',
            'Get help and contact support',
          ),
          _buildFeatureItem(
            'Seat Booking',
            'Pick a seat on rides you joined',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFFF98825), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF98825),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
