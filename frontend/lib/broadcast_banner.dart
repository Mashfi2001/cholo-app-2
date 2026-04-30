import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'backend_config.dart';

class BroadcastBanner extends StatefulWidget {
  const BroadcastBanner({Key? key}) : super(key: key);

  @override
  _BroadcastBannerState createState() => _BroadcastBannerState();
}

class _BroadcastBannerState extends State<BroadcastBanner> {
  List<dynamic> broadcasts = [];
  bool isLoading = true;
  final Set<int> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    fetchBroadcasts();
  }

  Future<void> fetchBroadcasts() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/broadcasts/active'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          broadcasts = data;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() => isLoading = false);
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ALERT':
        return Colors.red.shade700;
      case 'MAINTENANCE':
        return Colors.orange.shade700;
      case 'ANNOUNCEMENT':
      default:
        return Colors.blue.shade700;
    }
  }

  Color _getTypeBgColor(String type) {
    switch (type) {
      case 'ALERT':
        return Colors.red.shade50;
      case 'MAINTENANCE':
        return Colors.orange.shade50;
      case 'ANNOUNCEMENT':
      default:
        return Colors.blue.shade50;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ALERT':
        return Icons.warning_amber_rounded;
      case 'MAINTENANCE':
        return Icons.build_circle;
      case 'ANNOUNCEMENT':
      default:
        return Icons.campaign;
    }
  }

  void _dismiss(int id) {
    setState(() {
      _dismissedIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || broadcasts.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleBroadcasts = broadcasts
        .where((b) => !_dismissedIds.contains(b['id']))
        .toList();

    if (visibleBroadcasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: visibleBroadcasts.map((b) {
        final color = _getTypeColor(b['type']);
        final bgColor = _getTypeBgColor(b['type']);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(_getTypeIcon(b['type']), color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b['title'],
                            style: TextStyle(color: color, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    content: Text(b['content']),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_getTypeIcon(b['type']), color: color, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b['content'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _dismiss(b['id']),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: color.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

