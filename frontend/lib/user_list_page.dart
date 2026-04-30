import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'backend_config.dart';
import 'user_profile_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({Key? key}) : super(key: key);

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedStatus = 'ACTIVE';
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers({String? status, String? role}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      String query = '$backendUrl/api/admin/users';
      Map<String, String> params = {};
      
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (role != null && role.isNotEmpty) params['role'] = role;

      final uri = Uri.parse(query);
      final uriWithParams = uri.replace(queryParameters: params.isNotEmpty ? params : null);
      
      final response = await http.get(uriWithParams);
      
      if (response.statusCode == 200) {
        final allUsers = json.decode(response.body);
        setState(() {
          users = allUsers;
          filteredUsers = allUsers;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load users (status ${response.statusCode})');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $error'))
      );
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      fetchUsers(status: selectedStatus, role: selectedRole);
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      String url = '$backendUrl/api/admin/users/search?query=$query';
      if (selectedRole != null && selectedRole!.isNotEmpty) {
        url += '&role=$selectedRole';
      }

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final searchResults = json.decode(response.body);
        setState(() {
          filteredUsers = searchResults;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching users: $error'))
      );
    }
  }

  void _filterUsers() {
    if (_searchController.text.isEmpty) {
      setState(() {
        filteredUsers = users;
      });
    } else {
      searchUsers(_searchController.text);
    }
  }

  Future<void> _suspendUser(int userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suspend $userName for how many days?'),
            SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '30',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: '30'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.put(
                  Uri.parse('$backendUrl/api/admin/users/$userId/suspend'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'days': 30}),
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User suspended successfully'))
                  );
                  fetchUsers(status: selectedStatus, role: selectedRole);
                }
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error'))
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _unsuspendUser(int userId, String userName) async {
    try {
      final response = await http.put(
        Uri.parse('$backendUrl/api/admin/users/$userId/unsuspend'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User unsuspended successfully'))
        );
        fetchUsers(status: selectedStatus, role: selectedRole);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'))
      );
    }
  }

  Future<void> _deleteUser(int userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Permanently delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.delete(
                  Uri.parse('$backendUrl/api/admin/users/$userId'),
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User deleted successfully'))
                  );
                  fetchUsers(status: selectedStatus, role: selectedRole);
                }
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error'))
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
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
          'User Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Panel
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Search',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 12),
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by ID, name, or email...',
                    prefixIcon: Icon(Icons.search, color: brandOrange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                // Filter Chips
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text('All'),
                      selected: selectedStatus == null,
                      onSelected: (selected) {
                        setState(() => selectedStatus = null);
                        fetchUsers(status: null, role: selectedRole);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: brandOrange.withOpacity(0.3),
                    ),
                    FilterChip(
                      label: Text('Active'),
                      selected: selectedStatus == 'ACTIVE',
                      onSelected: (selected) {
                        setState(() => selectedStatus = 'ACTIVE');
                        fetchUsers(status: 'ACTIVE', role: selectedRole);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.green.withOpacity(0.3),
                    ),
                    FilterChip(
                      label: Text('Suspended'),
                      selected: selectedStatus == 'SUSPENDED',
                      onSelected: (selected) {
                        setState(() => selectedStatus = 'SUSPENDED');
                        fetchUsers(status: 'SUSPENDED', role: selectedRole);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.orange.withOpacity(0.3),
                    ),
                    FilterChip(
                      label: Text('Deleted'),
                      selected: selectedStatus == 'DELETED',
                      onSelected: (selected) {
                        setState(() => selectedStatus = 'DELETED');
                        fetchUsers(status: 'DELETED', role: selectedRole);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.red.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Failed to load users',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: darkText,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => fetchUsers(
                                    status: selectedStatus, role: selectedRole),
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? const Center(child: Text('No users found'))
                        : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final status = user['status'] ?? 'ACTIVE';
                          final Color statusColor = status == 'ACTIVE'
                              ? Colors.green
                              : status == 'SUSPENDED'
                                  ? Colors.orange
                                  : Colors.red;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['name'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: darkText,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'ID: ${user['id']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    user['email'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Role: ${user['role']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (user['suspendedUntil'] != null)
                                    Text(
                                      'Suspended until: ${DateTime.parse(user['suspendedUntil']).toLocal().toString().split('.')[0]}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  SizedBox(height: 12),
                                  // Action Buttons
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (status == 'ACTIVE')
                                        ElevatedButton.icon(
                                          onPressed: () => _suspendUser(
                                            user['id'],
                                            user['name'],
                                          ),
                                          icon: Icon(Icons.pause),
                                          label: Text('Suspend'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      if (status == 'SUSPENDED')
                                        ElevatedButton.icon(
                                          onPressed: () => _unsuspendUser(
                                            user['id'],
                                            user['name'],
                                          ),
                                          icon: Icon(Icons.check),
                                          label: Text('Unsuspend'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ),
                                        ),
                                      ElevatedButton.icon(
                                        onPressed: () => _deleteUser(
                                          user['id'],
                                          user['name'],
                                        ),
                                        icon: Icon(Icons.delete),
                                        label: Text('Delete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
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
          ),
        ],
      ),
    );
  }
}
