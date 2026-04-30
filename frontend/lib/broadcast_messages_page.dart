import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'backend_config.dart';

class BroadcastMessagesPage extends StatefulWidget {
  const BroadcastMessagesPage({Key? key}) : super(key: key);

  @override
  _BroadcastMessagesPageState createState() => _BroadcastMessagesPageState();
}

class _BroadcastMessagesPageState extends State<BroadcastMessagesPage> {
  List<dynamic> broadcasts = [];
  bool isLoading = true;
  String? errorMessage;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String _selectedType = 'ANNOUNCEMENT';

  final List<String> _types = ['ANNOUNCEMENT', 'ALERT', 'MAINTENANCE'];

  @override
  void initState() {
    super.initState();
    fetchBroadcasts();
  }

  Future<void> fetchBroadcasts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('$backendUrl/api/broadcasts'),
      );

      if (response.statusCode == 200) {
        setState(() {
          broadcasts = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load broadcasts');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  Future<void> createBroadcast() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/broadcasts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'content': _contentController.text,
          'type': _selectedType,
        }),
      );

      if (response.statusCode == 201) {
        _titleController.clear();
        _contentController.clear();
        setState(() => _selectedType = 'ANNOUNCEMENT');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast created successfully')),
        );
        fetchBroadcasts();
      } else {
        throw Exception('Failed to create broadcast');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> toggleBroadcast(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$backendUrl/api/broadcasts/$id/toggle'),
      );

      if (response.statusCode == 200) {
        fetchBroadcasts();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> deleteBroadcast(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/broadcasts/$id'),
      );

      if (response.statusCode == 200) {
        fetchBroadcasts();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ALERT':
        return Colors.red;
      case 'MAINTENANCE':
        return Colors.orange;
      case 'ANNOUNCEMENT':
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ALERT':
        return Icons.warning_amber;
      case 'MAINTENANCE':
        return Icons.build;
      case 'ANNOUNCEMENT':
      default:
        return Icons.campaign;
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Broadcast'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              createBroadcast();
            },
            child: const Text('Send Broadcast'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color brandOrange = const Color(0xFFF98825);
    final Color darkText = const Color(0xFF2C323A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: brandOrange,
        title: const Text(
          'Broadcast Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: brandOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $errorMessage'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: fetchBroadcasts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : broadcasts.isEmpty
                  ? const Center(child: Text('No broadcasts yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: broadcasts.length,
                      itemBuilder: (context, index) {
                        final b = broadcasts[index];
                        final typeColor = _getTypeColor(b['type']);
                        final isActive = b['active'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getTypeIcon(b['type']),
                                      color: typeColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        b['type'],
                                        style: TextStyle(
                                          color: typeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isActive ? 'ACTIVE' : 'INACTIVE',
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.green
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  b['title'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['content'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => toggleBroadcast(b['id']),
                                      icon: Icon(
                                        isActive
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      label: Text(
                                        isActive ? 'Deactivate' : 'Activate',
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => deleteBroadcast(b['id']),
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

