import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../backend_config.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<dynamic> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/admin/complaints'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _complaints = data['complaints'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading complaints: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveComplaint(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/complaints/$id/resolve'),
      );

      if (response.statusCode == 200) {
        _loadComplaints();
      }
    } catch (e) {
      print('Error resolving: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Complaints',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),
            ),

            // Complaints list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : _complaints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.silverMid, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No open complaints',
                                style: AppTextStyles.headingL.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _complaints.length,
                          itemBuilder: (context, index) {
                            final complaint = _complaints[index];
                            return _buildComplaintCard(complaint);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    final category = complaint['category'] ?? 'Other';
    final description = complaint['description'] ?? '';
    final status = complaint['status'] ?? 'OPEN';
    final userName = complaint['user']?['name'] ?? 'Unknown';
    final userType = complaint['userType'] ?? 'PASSENGER';
    final createdAt = complaint['createdAt'] ?? '';

    Color statusColor;
    switch (status) {
      case 'RESOLVED':
        statusColor = AppColors.successGreen;
        break;
      case 'IN_PROGRESS':
        statusColor = AppColors.warningAmber;
        break;
      default:
        statusColor = AppColors.dangerRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.report_problem,
                  color: AppColors.dangerRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'By $userName ($userType)',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: AppTextStyles.bodyM,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(createdAt),
                style: AppTextStyles.caption,
              ),
              if (status == 'OPEN')
                TextButton(
                  onPressed: () => _resolveComplaint(complaint['id']),
                  child: Text(
                    'Mark Resolved',
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
