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

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  File? _nidFront;
  File? _nidBack;
  File? _license;
  final _nidNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  DateTime? _licenseExpiry;
  bool _isSubmitting = false;
  bool _isLoading = true;
  Map<String, dynamic>? _existingDocs;

  @override
  void initState() {
    super.initState();
    _loadExistingDocuments();
  }

  @override
  void dispose() {
    _nidNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/documents'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _existingDocs = data['documents'];
          if (_existingDocs != null) {
            _nidNumberController.text = _existingDocs!['nidNumber'] ?? '';
            _licenseNumberController.text = _existingDocs!['licenseNumber'] ?? '';
            if (_existingDocs!['licenseExpiry'] != null) {
              _licenseExpiry = DateTime.parse(_existingDocs!['licenseExpiry']);
            }
          }
        });
      }
    } catch (e) {
      print('Error loading documents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(bool isNid, bool isFront) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    
    if (picked != null) {
      setState(() {
        if (isNid) {
          if (isFront) {
            _nidFront = File(picked.path);
          } else {
            _nidBack = File(picked.path);
          }
        } else {
          _license = File(picked.path);
        }
      });
    }
  }

  Future<void> _selectLicenseExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.pureWhite,
            surface: AppColors.surfaceBlack,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _licenseExpiry = picked);
    }
  }

  Future<void> _submitDocuments() async {
    if (_nidNumberController.text.isEmpty || _licenseNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter all document numbers',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    if (_licenseExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select license expiry date',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // In a real app, you would upload images first and get URLs back
      // For now, we'll just send the document numbers
      final response = await http.post(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/documents'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nidNumber': _nidNumberController.text,
          'licenseNumber': _licenseNumberController.text,
          'licenseExpiry': _licenseExpiry!.toIso8601String(),
          'hasNidFront': _nidFront != null || (_existingDocs?['nidFrontUrl'] != null),
          'hasNidBack': _nidBack != null || (_existingDocs?['nidBackUrl'] != null),
          'hasLicense': _license != null || (_existingDocs?['licenseUrl'] != null),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSheet();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Failed to submit documents',
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

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.successGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Documents Submitted!',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll review your documents within 24 hours.',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Got it',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnderReview = _existingDocs?['status'] == 'PENDING';
    final isVerified = _existingDocs?['status'] == 'VERIFIED';

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.pureWhite),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App bar
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Verify Documents',
                          style: AppTextStyles.headingM,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Status badge
                    if (isUnderReview)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warningAmber),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top, color: AppColors.warningAmber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UNDER REVIEW',
                                    style: AppTextStyles.labelBold.copyWith(
                                      color: AppColors.warningAmber,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Submitted on ${_formatDate(_existingDocs?['submittedAt'])}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isVerified)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.successGreen),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, color: AppColors.successGreen),
                            const SizedBox(width: 12),
                            Text(
                              'VERIFIED',
                              style: AppTextStyles.labelBold.copyWith(
                                color: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBlack,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info, color: AppColors.silverMid),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Documents are reviewed within 24 hours.',
                                style: AppTextStyles.bodyM,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // NID Section
                    CustomCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'National ID Card',
                            style: AppTextStyles.headingL.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          
                          // Upload boxes
                          Row(
                            children: [
                              Expanded(
                                child: _buildUploadBox(
                                  label: 'Front',
                                  isUploaded: _nidFront != null || 
                                      (_existingDocs?['nidFrontUrl'] != null && !isUnderReview),
                                  onTap: isUnderReview ? null : () => _pickImage(true, true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildUploadBox(
                                  label: 'Back',
                                  isUploaded: _nidBack != null || 
                                      (_existingDocs?['nidBackUrl'] != null && !isUnderReview),
                                  onTap: isUnderReview ? null : () => _pickImage(true, false),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // NID Number field
                          TextField(
                            controller: _nidNumberController,
                            enabled: !isUnderReview,
                            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                            decoration: InputDecoration(
                              labelText: 'NID Number',
                              labelStyle: AppTextStyles.bodyM,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderGray),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderGray),
                              ),
                              filled: true,
                              fillColor: AppColors.cardBlack,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // License Section
                    CustomCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driving License',
                            style: AppTextStyles.headingL.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 20),
                          
                          // License upload
                          _buildUploadBox(
                            label: 'License Photo',
                            isUploaded: _license != null || 
                                (_existingDocs?['licenseUrl'] != null && !isUnderReview),
                            onTap: isUnderReview ? null : () => _pickImage(false, false),
                            fullWidth: true,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // License Number field
                          TextField(
                            controller: _licenseNumberController,
                            enabled: !isUnderReview,
                            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                            decoration: InputDecoration(
                              labelText: 'License Number',
                              labelStyle: AppTextStyles.bodyM,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderGray),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.borderGray),
                              ),
                              filled: true,
                              fillColor: AppColors.cardBlack,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Expiry date picker
                          GestureDetector(
                            onTap: isUnderReview ? null : _selectLicenseExpiry,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBlack,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderGray),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: AppColors.silverMid),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'License Expiry',
                                          style: AppTextStyles.caption,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _licenseExpiry != null
                                              ? '${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}'
                                              : 'Select date',
                                          style: AppTextStyles.bodyL.copyWith(
                                            color: _licenseExpiry != null 
                                                ? AppColors.pureWhite 
                                                : AppColors.silverMid,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.silverMid),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit button (only if not under review)
                    if (!isUnderReview && !isVerified)
                      CustomButton(
                        label: 'Submit for Verification',
                        onPressed: _isSubmitting ? null : _submitDocuments,
                        isLoading: _isSubmitting,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required bool isUploaded,
    required VoidCallback? onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.successGreen.withOpacity(0.1) : AppColors.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUploaded ? AppColors.successGreen : AppColors.borderGray,
            style: onTap == null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle : Icons.camera_alt,
              color: isUploaded ? AppColors.successGreen : AppColors.silverMid,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              isUploaded ? 'Uploaded' : label,
              style: AppTextStyles.bodyM.copyWith(
                color: isUploaded ? AppColors.successGreen : AppColors.silverMid,
              ),
            ),
            if (isUploaded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Re-upload',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.silverLight,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}
