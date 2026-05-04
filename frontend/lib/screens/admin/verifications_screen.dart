import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../backend_config.dart';

class VerificationsScreen extends StatefulWidget {
  const VerificationsScreen({super.key});

  @override
  State<VerificationsScreen> createState() => _VerificationsScreenState();
}

class _VerificationsScreenState extends State<VerificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _driverVerifications = [];
  List<dynamic> _passengerVerifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVerifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVerifications() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/admin/verifications'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _driverVerifications = data['drivers'] ?? [];
          _passengerVerifications = data['passengers'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading verifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveVerification(dynamic verification) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/verifications/${verification['id']}/approve'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification approved',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        _loadVerifications();
      }
    } catch (e) {
      print('Error approving: $e');
    }
  }

  Future<void> _rejectVerification(dynamic verification, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/admin/verifications/${verification['id']}/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification rejected',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
        _loadVerifications();
      }
    } catch (e) {
      print('Error rejecting: $e');
    }
  }

  void _showRejectSheet(dynamic verification) {
    final reasonController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
              const Icon(
                Icons.close,
                color: AppColors.dangerRed,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Reject Verification',
                style: AppTextStyles.headingL,
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide a reason for rejection',
                style: AppTextStyles.bodyM,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: 'Enter rejection reason...',
                    hintStyle: AppTextStyles.bodyM,
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Reject',
                variant: CustomButtonVariant.danger,
                onPressed: () {
                  if (reasonController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    _rejectVerification(verification, reasonController.text.trim());
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Cancel',
                variant: CustomButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageViewer(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.pureWhite,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
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
                    'Verifications',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.primaryBlack,
                unselectedLabelColor: AppColors.silverMid,
                labelStyle: AppTextStyles.labelBold.copyWith(fontSize: 12),
                unselectedLabelStyle: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Drivers'),
                        if (_driverVerifications.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warningAmber,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${_driverVerifications.length}',
                              style: const TextStyle(
                                color: AppColors.primaryBlack,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Passengers'),
                        if (_passengerVerifications.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warningAmber,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${_passengerVerifications.length}',
                              style: const TextStyle(
                                color: AppColors.primaryBlack,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVerificationsList(_driverVerifications, isDriver: true),
                  _buildVerificationsList(_passengerVerifications, isDriver: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationsList(List<dynamic> verifications, {required bool isDriver}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.pureWhite),
      );
    }

    if (verifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.silverMid, size: 64),
            const SizedBox(height: 16),
            Text(
              'No pending verifications',
              style: AppTextStyles.headingL.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'All ${isDriver ? "driver" : "passenger"} verifications are up to date',
              style: AppTextStyles.bodyM,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: verifications.length,
      itemBuilder: (context, index) {
        final verification = verifications[index];
        return _buildVerificationCard(verification, isDriver);
      },
    );
  }

  Widget _buildVerificationCard(dynamic verification, bool isDriver) {
    final name = verification['user']?['name'] ?? 'Unknown';
    final submittedAt = verification['submittedAt'] ?? 'Recently';
    final nidFront = verification['nidFrontUrl'];
    final nidBack = verification['nidBackUrl'];
    final license = verification['licenseUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: const Icon(Icons.person, color: AppColors.silverLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted $submittedAt',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Document thumbnails
          if (isDriver) ...[
            Row(
              children: [
                Expanded(
                  child: _buildThumbnail(
                    label: 'NID Front',
                    imageUrl: nidFront,
                    onTap: () => nidFront != null ? _showImageViewer(nidFront) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThumbnail(
                    label: 'NID Back',
                    imageUrl: nidBack,
                    onTap: () => nidBack != null ? _showImageViewer(nidBack) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThumbnail(
                    label: 'License',
                    imageUrl: license,
                    onTap: () => license != null ? _showImageViewer(license) : null,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildThumbnail(
                    label: 'NID Front',
                    imageUrl: nidFront,
                    onTap: () => nidFront != null ? _showImageViewer(nidFront) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildThumbnail(
                    label: 'NID Back',
                    imageUrl: nidBack,
                    onTap: () => nidBack != null ? _showImageViewer(nidBack) : null,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: AppColors.borderGray, height: 1),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectSheet(verification),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerRed,
                    side: const BorderSide(color: AppColors.dangerRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(
                    'Reject',
                    style: AppTextStyles.labelBold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveVerification(verification),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pureWhite,
                    foregroundColor: AppColors.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    'Approve',
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.primaryBlack,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail({
    required String label,
    String? imageUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: imageUrl != null ? null : AppColors.surfaceBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGray),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: imageUrl == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported,
                      color: AppColors.silverMid,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
