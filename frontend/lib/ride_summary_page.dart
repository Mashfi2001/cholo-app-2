import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'backend_config.dart';

class RideSummaryPage extends StatefulWidget {
  final Map<String, dynamic> ride;

  const RideSummaryPage({Key? key, required this.ride}) : super(key: key);

  @override
  State<RideSummaryPage> createState() => _RideSummaryPageState();
}

class _RideSummaryPageState extends State<RideSummaryPage> {
  bool isLoading = true;
  int gotTotalMoney = 0;
  int totalFare = 0;
  int bookedSeats = 0;
  List<Map<String, dynamic>> paidBreakdown = [];

  int? get rideId => widget.ride["id"] is int
      ? widget.ride["id"] as int
      : int.tryParse(widget.ride["id"].toString());

  @override
  void initState() {
    super.initState();
    fetchSummaryData();
  }

  Future<void> fetchSummaryData() async {
    if (rideId == null) return;
    try {
      final response = await http.get(
        Uri.parse("$backendUrl/seat-booking/$rideId/seats"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          final gm = data["gotTotalMoney"];
          gotTotalMoney = gm is num ? gm.ceil() : int.tryParse(gm?.toString() ?? '0') ?? 0;
          
          final tf = data["totalFare"];
          totalFare = tf is num ? tf.ceil() : int.tryParse(tf?.toString() ?? '0') ?? 0;
          
          paidBreakdown = List<Map<String, dynamic>>.from(data["paidBreakdown"] ?? []);
          
          final seats = List<Map<String, dynamic>>.from(data["seats"] ?? []);
          bookedSeats = seats.where((s) => s["state"] == "BOOKED" || s["state"] == "BOOKED_BY_ME").length + paidBreakdown.length;
        });
      }
    } catch (e) {
      print("Error fetching summary: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ride Summary"),
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back normally
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 60),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ride Completed Successfully!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Here's a summary of your trip.",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  
                  // Earnings Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Total Expected Earnings",
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$totalFare Tk",
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Grid
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(Icons.people_alt_outlined, "Passengers", "$bookedSeats")),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          Icons.route_outlined, 
                          "Distance", 
                          "${(widget.ride['routeDistanceKm'] is num ? (widget.ride['routeDistanceKm'] as num).toDouble() : double.tryParse(widget.ride['routeDistanceKm'].toString()) ?? 0).toStringAsFixed(1)} km"
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          Icons.schedule, 
                          "Duration", 
                          "${(widget.ride['routeDurationMin'] is num ? (widget.ride['routeDurationMin'] as num).toDouble() : double.tryParse(widget.ride['routeDurationMin'].toString()) ?? 0).toStringAsFixed(0)} min"
                        )
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Route info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _routePoint(widget.ride['origin'] ?? 'Origin', true),
                        Padding(
                          padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(width: 2, height: 20, color: Colors.grey.shade300),
                          ),
                        ),
                        _routePoint(widget.ride['destination'] ?? 'Destination', false),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back to the very root (dashboard)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF98825),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Back to Dashboard",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF98825), size: 24),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _routePoint(String text, bool isOrigin) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOrigin ? const Color(0xFF16A34A) : const Color(0xFFF98825),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: (isOrigin ? const Color(0xFF16A34A) : const Color(0xFFF98825)).withOpacity(0.3),
                blurRadius: 4,
              )
            ]
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
