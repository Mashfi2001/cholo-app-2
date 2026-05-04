import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../session.dart';
import '../../backend_config.dart';

class ChatScreen extends StatefulWidget {
  final int rideId;
  final String rideTitle;
  final int otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.rideId,
    required this.rideTitle,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/rides/${widget.rideId}/messages'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages = data['messages'] ?? [];
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/rides/${widget.rideId}/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': Session.userId,
          'receiverId': widget.otherUserId,
          'text': text,
        }),
      );

      if (response.statusCode == 201) {
        _loadMessages();
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBlack,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
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
                    widget.otherUserName,
                    style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Ride info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              border: Border(
                bottom: BorderSide(color: AppColors.borderGray),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car, 
                  color: AppColors.silverMid, 
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.rideTitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.pureWhite),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, 
                              color: AppColors.silverMid, 
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: AppTextStyles.headingL.copyWith(fontSize: 20),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start the conversation',
                              style: AppTextStyles.bodyM,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['senderId'] == Session.userId;
                          return _buildMessageBubble(message, isMe);
                        },
                      ),
          ),

          // Input row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBlack,
              border: Border(
                top: BorderSide(color: AppColors.borderGray),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTextStyles.bodyM,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.pureWhite,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: AppColors.primaryBlack,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isMe) {
    final text = message['text'] ?? '';
    final timestamp = message['createdAt'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.pureWhite : AppColors.cardBlack,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe 
              ? null 
              : Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: AppTextStyles.bodyL.copyWith(
                color: isMe ? AppColors.primaryBlack : AppColors.pureWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(timestamp),
              style: AppTextStyles.caption.copyWith(
                color: isMe ? AppColors.silverMid : AppColors.silverLight,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return '';
    try {
      final date = DateTime.parse(timestamp);
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final suffix = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    } catch (e) {
      return '';
    }
  }
}
