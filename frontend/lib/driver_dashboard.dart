import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'driver_panel.dart';
import 'my_rides_page_driver.dart';
import 'verification_request_page.dart';
import 'login_screen.dart';
import 'session.dart';
import 'complaints_page.dart';
import 'backend_config.dart';
import 'DriverProfilePage.dart';

class DriverDashboard extends StatefulWidget {
  final int userId;
  final String userName;

  const DriverDashboard({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  Map<String, dynamic>? activeRide;
  bool isLoading = true;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchActiveRide(),
      _fetchNotifications(),
    ]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _fetchNotifications() async {
    try {
      final notifRes = await http.get(
        Uri.parse('$backendUrl/api/notifications/user/${widget.userId}'),
      );
      if (notifRes.statusCode == 200) {
        final notifBody = jsonDecode(notifRes.body);
        setState(() {
          notifications = List<dynamic>.from(notifBody['notifications'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/notifications/$id'),
      );
      if (response.statusCode == 200) {
        setState(() {
          notifications.removeWhere((n) => n['id'] == id);
        });
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: double.maxFinite,
          child: notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      leading: Icon(
                        n['type'] == 'WARNING' ? Icons.warning : 
                        n['type'] == 'SUCCESS' ? Icons.check_circle : Icons.info,
                        color: n['type'] == 'WARNING' ? Colors.orange : 
                               n['type'] == 'SUCCESS' ? Colors.green : Colors.blue,
                      ),
                      title: Text(n['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(n['message'], style: const TextStyle(fontSize: 12)),
                      contentPadding: EdgeInsets.zero,
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          deleteNotification(n['id']);
                          Navigator.pop(context);
                          _showNotifications();
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _fetchActiveRide() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/rides/driver/${widget.userId}/active'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          activeRide = data['ride'];
        });
      }
    } catch (e) {
      print('Error fetching active ride: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color brandOrange = const Color(0xFFF98825);
    final Color darkText = const Color(0xFF2C323A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Logged in as ${widget.userName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: _showNotifications,
              ),
              if (notifications.any((n) => n['isRead'] == false))
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Image.asset('assets/cholo_logo.png', height: 80),
                  const SizedBox(height: 24),
                  Text(
                    'Driver Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
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

                  // Row 1: Create Ride / Current Ride & My Rides
                  Row(
                    children: [
                      Expanded(
                        child: activeRide == null
                            ? _buildActionButton(
                                'Create Ride',
                                Icons.add_circle_outline,
                                () {
                                  Navigator.of(context)
                                      .push(
                                    MaterialPageRoute(
                                      builder: (context) => DriverPanel(
                                        userId: widget.userId,
                                        userName: widget.userName,
                                      ),
                                    ),
                                  )
                                      .then((_) => fetchData());
                                },
                              )
                            : _buildActionButton(
                                'Current Ride',
                                Icons.directions_car,
                                () {
                                  Navigator.of(context)
                                      .push(
                                    MaterialPageRoute(
                                      builder: (context) => DriverPanel(
                                        userId: widget.userId,
                                        userName: widget.userName,
                                      ),
                                    ),
                                  )
                                      .then((_) => fetchData());
                                },
                                color: Colors.green,
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
                                  builder: (_) => const MyRidesPageDriver()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Profile & Verify Profile
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Profile',
                          Icons.person_outline,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DriverProfilePage(
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Verify Profile',
                          Icons.verified_user,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => VerificationRequestPage(
                                  userId: widget.userId,
                                  userName: widget.userName,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 3: Support & Logout
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Support',
                          Icons.help,
                          () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          'Logout',
                          Icons.logout,
                          () {
                            Session.logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
  }) {
    final Color brandOrange = const Color(0xFFF98825);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? brandOrange,
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