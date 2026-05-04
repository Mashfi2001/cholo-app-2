import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../session.dart';
import '../../backend_config.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/users/${Session.userId}/notifications'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['notifications'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/users/${Session.userId}/notifications/mark-read'),
      );

      if (response.statusCode == 200) {
        _loadNotifications();
      }
    } catch (e) {
      print('Error marking read: $e');
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/notifications/$notificationId/mark-read'),
      );

      if (response.statusCode == 200) {
        _loadNotifications();
      }
    } catch (e) {
      print('Error marking read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;

    // Group notifications by date
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    final todayNotifications = _notifications.where((n) {
      final date = DateTime.parse(n['createdAt']);
      return _isSameDay(date, today);
    }).toList();
    
    final yesterdayNotifications = _notifications.where((n) {
      final date = DateTime.parse(n['createdAt']);
      return _isSameDay(date, yesterday);
    }).toList();
    
    final earlierNotifications = _notifications.where((n) {
      final date = DateTime.parse(n['createdAt']);
      return date.isBefore(yesterday);
    }).toList();

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
                        'Notifications',
                        style: AppTextStyles.headingM,
                      ),
                    ],
                  ),
                  if (unreadCount > 0)
                    GestureDetector(
                      onTap: _markAllRead,
                      child: Text(
                        'Mark all read',
                        style: AppTextStyles.labelBold.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Notifications list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : _notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off, color: AppColors.silverMid, size: 64),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications',
                                style: AppTextStyles.headingL.copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            if (todayNotifications.isNotEmpty) ...[
                              _buildDateHeader('Today'),
                              ...todayNotifications.map((n) => _buildNotificationRow(n)),
                            ],
                            if (yesterdayNotifications.isNotEmpty) ...[
                              _buildDateHeader('Yesterday'),
                              ...yesterdayNotifications.map((n) => _buildNotificationRow(n)),
                            ],
                            if (earlierNotifications.isNotEmpty) ...[
                              _buildDateHeader('Earlier'),
                              ...earlierNotifications.map((n) => _buildNotificationRow(n)),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        date,
        style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildNotificationRow(dynamic notification) {
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'system';
    final createdAt = notification['createdAt'] ?? '';

    final (icon, color) = _getNotificationIcon(type);

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['id']);
        }
        // Navigate to relevant screen based on type
        _handleNotificationTap(type, notification);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surfaceBlack : AppColors.cardBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: isRead ? Colors.transparent : AppColors.pureWhite,
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyL.copyWith(
                      color: AppColors.pureWhite,
                      fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTextStyles.bodyM,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return (Icons.event_seat, AppColors.silverLight);
      case 'ride':
        return (Icons.directions_car, AppColors.successGreen);
      case 'complaint':
        return (Icons.report_problem, AppColors.dangerRed);
      case 'verification':
        return (Icons.verified_user, AppColors.warningAmber);
      default:
        return (Icons.notifications, AppColors.silverMid);
    }
  }

  void _handleNotificationTap(String type, dynamic notification) {
    // Navigate based on notification type
    switch (type) {
      case 'booking':
        // Navigate to ride detail
        break;
      case 'ride':
        // Navigate to active ride
        break;
      case 'complaint':
        // Navigate to complaint detail
        break;
      case 'verification':
        // Navigate to verification status
        break;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTimeAgo(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return '';
    }
  }
}
