import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

class DriverProfilePage extends StatefulWidget {
  final int userId;

  const DriverProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? ratingData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => isLoading = true);
    try {
      final userRes = await http.get(Uri.parse('$backendUrl/api/auth/${widget.userId}'));
      final ratingRes = await http.get(Uri.parse('$backendUrl/api/ratings/driver/${widget.userId}/average'));

      if (userRes.statusCode == 200 && ratingRes.statusCode == 200) {
        setState(() {
          userData = jsonDecode(userRes.body);
          ratingData = jsonDecode(ratingRes.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandOrange = const Color(0xFFF98825);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Driver Profile'),
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
              ? const Center(child: Text('Failed to load profile'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Color(0xFFF98825),
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData!['name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildRatingSection(),
                      const SizedBox(height: 32),
                      _buildInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRatingSection() {
    if (ratingData == null) return const SizedBox.shrink();

    final avg = ratingData!['averageRating'] ?? 0.0;
    final count = ratingData!['totalRatings'] ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < avg.floor() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 24,
          );
        }),
        const SizedBox(width: 8),
        Text(
          '${avg.toStringAsFixed(1)} ($count reviews)',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.email_outlined, 'Email', userData!['email']),
          const Divider(height: 32),
          _buildInfoRow(Icons.phone_outlined, 'Phone', userData!['phone'] ?? 'Not set'),
          const Divider(height: 32),
          _buildInfoRow(Icons.work_outline, 'Role', userData!['role']),
          const Divider(height: 32),
          _buildInfoRow(Icons.calendar_today_outlined, 'Joined', 
            userData!['createdAt'] != null 
              ? userData!['createdAt'].toString().substring(0, 10) 
              : 'N/A'
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 22),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
