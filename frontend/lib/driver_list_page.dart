import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'backend_config.dart';
import 'user_profile_page.dart';

class DriverListPage extends StatefulWidget {
  const DriverListPage({Key? key}) : super(key: key);

  @override
  _DriverListPageState createState() => _DriverListPageState();
}

class _DriverListPageState extends State<DriverListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> drivers = [];
  List<dynamic> filteredDrivers = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedStatus = 'ACTIVE';

  @override
  void initState() {
    super.initState();
    fetchDrivers();
    _searchController.addListener(_filterDrivers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDrivers({String? status}) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      String query = '$backendUrl/api/admin/users';
      Map<String, String> params = {'role': 'DRIVER'};
      
      if (status != null && status.isNotEmpty) params['status'] = status;

      final uri = Uri.parse(query);
      final uriWithParams = uri.replace(queryParameters: params);
      
      final response = await http.get(uriWithParams);
      
      if (response.statusCode == 200) {
        final allDrivers = json.decode(response.body);
        setState(() {
          drivers = allDrivers;
          filteredDrivers = allDrivers;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load drivers (status ${response.statusCode})');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading drivers: $error'))
      );
    }
  }

  Future<void> searchDrivers(String query) async {
    if (query.isEmpty) {
      fetchDrivers(status: selectedStatus);
      return;
    }

    try {
      setState(() => isLoading = true);
      
      String url = '$backendUrl/api/admin/users/search?query=$query&role=DRIVER';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final searchResults = json.decode(response.body);
        setState(() {
          filteredDrivers = searchResults;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching drivers: $error'))
      );
    }
  }

  void _filterDrivers() {
    if (_searchController.text.isEmpty) {
      setState(() {
        filteredDrivers = drivers;
      });
    } else {
      searchDrivers(_searchController.text);
    }
  }

  Future<void> _suspendDriver(int driverId, String driverName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suspend Driver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suspend $driverName for how many days?'),
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
                  Uri.parse('$backendUrl/api/admin/users/$driverId/suspend'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'days': 30}),
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Driver suspended successfully'))
                  );
                  fetchDrivers(status: selectedStatus);
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

  Future<void> _unsuspendDriver(int driverId, String driverName) async {
    try {
      final response = await http.put(
        Uri.parse('$backendUrl/api/admin/users/$driverId/unsuspend'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver unsuspended successfully'))
        );
        fetchDrivers(status: selectedStatus);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'))
      );
    }
  }

  Future<void> _deleteDriver(int driverId, String driverName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Driver'),
        content: Text('Permanently delete $driverName? This action cannot be undone.'),
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
                  Uri.parse('$backendUrl/api/admin/users/$driverId'),
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Driver deleted successfully'))
                  );
                  fetchDrivers(status: selectedStatus);
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
          'Driver Management',
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
                        fetchDrivers(status: null);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: brandOrange.withOpacity(0.3),
                    ),
                    FilterChip(
                      label: Text('Active'),
                      selected: selectedStatus == 'ACTIVE',
                      onSelected: (selected) {
                        setState(() => selectedStatus = 'ACTIVE');
                        fetchDrivers(status: 'ACTIVE');
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.green.withOpacity(0.3),
                    ),
                    FilterChip(
                      label: Text('Suspended'),
                      selected: selectedStatus == 'SUSPENDED',
                      onSelected: (selected) {
                        setState(() => selectedStatus = 'SUSPENDED');
                        fetchDrivers(status: 'SUSPENDED');
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.orange.withOpacity(0.3),
                    ),
                    FilterChip(
                      label: Text('Deleted'),
                      selected: selectedStatus == 'DELETED',
                      onSelected: (selected) {
                        setState(() => selectedStatus = 'DELETED');
                        fetchDrivers(status: 'DELETED');
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.red.withOpacity(0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Drivers List
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
                                'Failed to load drivers',
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
                                onPressed: () => fetchDrivers(
                                    status: selectedStatus),
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredDrivers.isEmpty
                        ? const Center(child: Text('No drivers found'))
                        : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = filteredDrivers[index];
                          final status = driver['status'] ?? 'ACTIVE';
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
                                              driver['name'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: darkText,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'ID: ${driver['id']}',
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
                                    driver['email'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (driver['suspendedUntil'] != null)
                                    Text(
                                      'Suspended until: ${DateTime.parse(driver['suspendedUntil']).toLocal().toString().split('.')[0]}',
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
                                          onPressed: () => _suspendDriver(
                                            driver['id'],
                                            driver['name'],
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
                                          onPressed: () => _unsuspendDriver(
                                            driver['id'],
                                            driver['name'],
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
                                        onPressed: () => _deleteDriver(
                                          driver['id'],
                                          driver['name'],
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

