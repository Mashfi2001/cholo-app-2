import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../backend_config.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/admin/announcements'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _announcements = data['announcements'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading announcements: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnnouncement(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/admin/announcements/$id'),
      );

      if (response.statusCode == 200) {
        _loadAnnouncements();
      }
    } catch (e) {
      print('Error deleting: $e');
    }
  }

  void _showCreateEditSheet({dynamic announcement}) {
    final isEditing = announcement != null;
    final titleController = TextEditingController(
      text: announcement?['title'] ?? '',
    );
    final messageController = TextEditingController(
      text: announcement?['message'] ?? '',
    );
    String target = announcement?['target'] ?? 'ALL';

    final targets = ['ALL', 'DRIVERS', 'PASSENGERS'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppColors.surfaceBlack,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderGray,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEditing ? 'Edit Announcement' : 'New Announcement',
                  style: AppTextStyles.headingL,
                ),
                const SizedBox(height: 24),
                
                // Title field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBlack,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: TextField(
                    controller: titleController,
                    style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                    decoration: InputDecoration(
                      hintText: 'Announcement title',
                      hintStyle: AppTextStyles.bodyM,
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Message field
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.cardBlack,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: TextField(
                    controller: messageController,
                    maxLines: 6,
                    style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                    decoration: InputDecoration(
                      hintText: 'Announcement message...',
                      hintStyle: AppTextStyles.bodyM,
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Target selector
                Text(
                  'Target Audience',
                  style: AppTextStyles.bodyM,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBlack,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: targets.map((t) {
                      final isSelected = target == t;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              target = t;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.pureWhite 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              t,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyM.copyWith(
                                color: isSelected 
                                    ? AppColors.primaryBlack 
                                    : AppColors.silverMid,
                                fontWeight: isSelected 
                                    ? FontWeight.w600 
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const Spacer(),
                
                CustomButton(
                  label: isEditing ? 'Update' : 'Publish',
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty &&
                        messageController.text.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _saveAnnouncement(
                        id: announcement?['id'],
                        title: titleController.text.trim(),
                        message: messageController.text.trim(),
                        target: target,
                      );
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
      ),
    );
  }

  Future<void> _saveAnnouncement({
    int? id,
    required String title,
    required String message,
    required String target,
  }) async {
    try {
      final response = id != null
          ? await http.put(
              Uri.parse('$backendUrl/api/admin/announcements/$id'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'title': title,
                'message': message,
                'target': target,
              }),
            )
          : await http.post(
              Uri.parse('$backendUrl/api/admin/announcements'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'title': title,
                'message': message,
                'target': target,
              }),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _loadAnnouncements();
      }
    } catch (e) {
      print('Error saving: $e');
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Announcements',
                        style: AppTextStyles.headingM,
                      ),
                    ],
                  ),
                  // Small primary button for + New
                  GestureDetector(
                    onTap: () => _showCreateEditSheet(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.pureWhite,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, 
                            color: AppColors.primaryBlack, 
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: AppTextStyles.labelBold.copyWith(
                              color: AppColors.primaryBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Announcements list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : _announcements.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.campaign, color: AppColors.silverMid, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No announcements',
                                style: AppTextStyles.headingL.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = _announcements[index];
                            return _buildAnnouncementCard(announcement);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic announcement) {
    final title = announcement['title'] ?? '';
    final message = announcement['message'] ?? '';
    final target = announcement['target'] ?? 'ALL';
    final createdAt = announcement['createdAt'] ?? '';

    Color targetColor;
    switch (target) {
      case 'DRIVERS':
        targetColor = AppColors.warningAmber;
        break;
      case 'PASSENGERS':
        targetColor = AppColors.silverLight;
        break;
      default:
        targetColor = AppColors.successGreen;
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
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: targetColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  target,
                  style: AppTextStyles.caption.copyWith(
                    color: targetColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyM,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(createdAt),
                style: AppTextStyles.caption,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showCreateEditSheet(announcement: announcement),
                    icon: const Icon(Icons.edit, color: AppColors.silverMid, size: 20),
                  ),
                  IconButton(
                    onPressed: () => _deleteAnnouncement(announcement['id']),
                    icon: const Icon(Icons.delete, color: AppColors.dangerRed, size: 20),
                  ),
                ],
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
