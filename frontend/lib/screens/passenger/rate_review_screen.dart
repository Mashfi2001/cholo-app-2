import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_input_field.dart';
import '../../session.dart';
import '../../backend_config.dart';

class RateReviewScreen extends StatefulWidget {
  final dynamic ride;

  const RateReviewScreen({
    super.key,
    required this.ride,
  });

  @override
  State<RateReviewScreen> createState() => _RateReviewScreenState();
}

class _RateReviewScreenState extends State<RateReviewScreen> {
  int _rating = 0;
  final List<String> _selectedTags = [];
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _availableTags = [
    'On time',
    'Safe driving',
    'Friendly',
    'Clean vehicle',
    'Good route',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a rating',
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
        Uri.parse('$backendUrl/api/rides/${widget.ride['id']}/review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': Session.userId,
          'rating': _rating,
          'tags': _selectedTags,
          'comment': _commentController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Review submitted!',
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
              data['error'] ?? 'Failed to submit review',
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
    final driverName = widget.ride['driver']?['name'] ?? 'Driver';
    final origin = widget.ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = widget.ride['destination']?.toString().split(',').first ?? 'Unknown';

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
                    'How was your ride?',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Driver card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBlack,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.silverLight,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: AppTextStyles.headingL.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$origin → $destination',
                            style: AppTextStyles.bodyM,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Star rating
              Center(
                child: Column(
                  children: [
                    Text(
                      'Rate your experience',
                      style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: index < _rating
                                  ? AppColors.warningAmber
                                  : AppColors.borderGray,
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Quick tags
              Text(
                'What went well?',
                style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.pureWhite : AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected ? AppColors.pureWhite : AppColors.borderGray,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.bodyM.copyWith(
                          color: isSelected ? AppColors.primaryBlack : AppColors.silverLight,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Comment field
              Text(
                'Additional comments (optional)',
                style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: AppTextStyles.bodyM,
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit button
              CustomButton(
                label: 'Submit Review',
                onPressed: _isSubmitting ? null : _submitReview,
                isLoading: _isSubmitting,
              ),

              const SizedBox(height: 16),

              // Skip button
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.bodyM.copyWith(
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
