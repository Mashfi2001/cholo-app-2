import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';

class DriverComplaintScreen extends StatefulWidget {
  const DriverComplaintScreen({super.key});

  @override
  State<DriverComplaintScreen> createState() => _DriverComplaintScreenState();
}

class _DriverComplaintScreenState extends State<DriverComplaintScreen> {
  String? _selectedCategory;
  final _descriptionController = TextEditingController();
  File? _evidencePhoto;
  bool _isSubmitting = false;
  dynamic _selectedRide;
  List<dynamic> _recentRides = [];

  final List<String> _categories = [
    'Passenger behavior',
    'No-show',
    'Payment issue',
    'Safety concern',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentRides();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentRides() async {
    if (Session.userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/rides/driver/${Session.userId}/history'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _recentRides = (data['rides'] ?? []).take(5).toList();
        });
      }
    } catch (e) {
      print('Error loading rides: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _evidencePhoto = File(picked.path);
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a complaint category',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please describe the issue',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/complaints'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': Session.userId,
          'userType': 'DRIVER',
          'rideId': _selectedRide?['id'],
          'category': _selectedCategory,
          'description': _descriptionController.text.trim(),
          'hasPhoto': _evidencePhoto != null,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Complaint submitted successfully',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.of(context).pop();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Failed to submit complaint',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'File Complaint',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Related ride selector
              if (_recentRides.isNotEmpty) ...[
                Text(
                  'Related Ride',
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showRideSelector(),
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          color: AppColors.silverLight,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRide != null
                                    ? '${_selectedRide['origin']?.toString().split(',').first} → ${_selectedRide['destination']?.toString().split(',').first}'
                                    : 'Select a ride (optional)',
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedRide != null)
                                Text(
                                  _formatDate(_selectedRide['departureTime'] ?? ''),
                                  style: AppTextStyles.caption,
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.silverLight,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Complaint categories
              Text(
                'Complaint Category',
                style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              ..._categories.map((category) => _buildCategoryOption(category)),

              const SizedBox(height: 24),

              // Description
              Text(
                'Describe the issue',
                style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue in detail...',
                    hintStyle: AppTextStyles.bodyM,
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Evidence photo
              Text(
                'Attach Evidence (Optional)',
                style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: _evidencePhoto != null
                    ? Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: FileImage(_evidencePhoto!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : _buildDottedUploadBox(),
              ),

              const SizedBox(height: 32),

              // Submit button
              CustomButton(
                label: 'Submit Complaint',
                onPressed: _isSubmitting ? null : _submitComplaint,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryOption(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pureWhite : AppColors.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.pureWhite : AppColors.borderGray,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlack : AppColors.silverMid,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryBlack : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        color: AppColors.pureWhite,
                        size: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              category,
              style: AppTextStyles.bodyL.copyWith(
                color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDottedUploadBox() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.silverMid,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.silverMid,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '+ Add Photo',
              style: AppTextStyles.bodyM,
            ),
          ],
        ),
      ),
    );
  }

  void _showRideSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select Ride',
                style: AppTextStyles.headingM,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _recentRides.length,
                itemBuilder: (context, index) {
                  final ride = _recentRides[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRide = ride;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_car,
                            color: AppColors.silverLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ride['origin']?.toString().split(',').first} → ${ride['destination']?.toString().split(',').first}',
                                  style: AppTextStyles.bodyL.copyWith(
                                    color: AppColors.pureWhite,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatDate(ride['departureTime'] ?? ''),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      return '$day/$month/$year';
    } catch (e) {
      return '';
    }
  }
}
