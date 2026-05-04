import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_input_field.dart';
import 'ride_results_screen.dart';
import 'location_search_page.dart';

class SearchRidesScreen extends StatefulWidget {
  const SearchRidesScreen({super.key});

  @override
  State<SearchRidesScreen> createState() => _SearchRidesScreenState();
}

class _SearchRidesScreenState extends State<SearchRidesScreen> {
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedSeats = 1;

  bool _isLoading = false;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  List<LatLng> _routePoints = [];

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.pureWhite,
              onPrimary: AppColors.primaryBlack,
              surface: AppColors.cardBlack,
              onSurface: AppColors.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.pureWhite,
              onPrimary: AppColors.primaryBlack,
              surface: AppColors.cardBlack,
              onSurface: AppColors.pureWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _incrementSeats() {
    if (_selectedSeats < 4) {
      setState(() => _selectedSeats++);
    }
  }

  void _decrementSeats() {
    if (_selectedSeats > 1) {
      setState(() => _selectedSeats--);
    }
  }

  Future<void> _searchRides() async {
    if (_pickupLocation == null || _destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select pickup and destination',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate?.year ?? DateTime.now().year,
        _selectedDate?.month ?? DateTime.now().month,
        _selectedDate?.day ?? DateTime.now().day,
        _selectedTime?.hour ?? TimeOfDay.now().hour,
        _selectedTime?.minute ?? TimeOfDay.now().minute,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RideResultsScreen(
            pickupLat: _pickupLocation!.latitude,
            pickupLng: _pickupLocation!.longitude,
            dropLat: _destinationLocation!.latitude,
            dropLng: _destinationLocation!.longitude,
            pickupName: _pickupController.text,
            dropName: _destinationController.text,
            requestedTime: dateTime.toIso8601String(),
            seats: _selectedSeats,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMapTap(LatLng point) async {
    if (_pickupLocation == null) {
      setState(() {
        _pickupLocation = point;
        _pickupController.text = "Loading...";
      });
      final locationName = await _reverseGeocode(point);
      setState(() => _pickupController.text = locationName);
    } else if (_destinationLocation == null) {
      setState(() {
        _destinationLocation = point;
        _destinationController.text = "Loading...";
      });
      final locationName = await _reverseGeocode(point);
      setState(() => _destinationController.text = locationName);
      await _fetchRoute();
    } else {
      setState(() {
        _pickupLocation = point;
        _destinationLocation = null;
        _pickupController.text = "Loading...";
        _destinationController.clear();
        _routePoints = [];
      });
      final locationName = await _reverseGeocode(point);
      setState(() => _pickupController.text = locationName);
    }
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}',
        ),
        headers: {'User-Agent': 'CholoApp'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['address'] != null) {
          final address = data['address'];
          return address['road'] ??
              address['suburb'] ??
              address['city'] ??
              address['town'] ??
              address['county'] ??
              'Unknown location';
        }
        if (data['display_name'] != null) {
          return data['display_name'];
        }
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
    return '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}';
  }

  Future<void> _fetchRoute() async {
    if (_pickupLocation == null || _destinationLocation == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${_pickupLocation!.longitude},${_pickupLocation!.latitude};${_destinationLocation!.longitude},${_destinationLocation!.latitude}?overview=full&geometries=geojson',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = coordinates
                .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                .toList();
          });
        }
      }
    } catch (e) {
      print('Route fetching error: $e');
    }
  }

  void _swapLocations() {
    setState(() {
      final tempLocation = _pickupLocation;
      _pickupLocation = _destinationLocation;
      _destinationLocation = tempLocation;

      final tempText = _pickupController.text;
      _pickupController.text = _destinationController.text;
      _destinationController.text = tempText;

      _routePoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Find a Ride',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    icon: Icons.calendar_today,
                    label: _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}'
                        : 'Date',
                    isSelected: _selectedDate != null,
                    onTap: _selectDate,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    icon: Icons.access_time,
                    label: _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'Time',
                    isSelected: _selectedTime != null,
                    onTap: _selectTime,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    icon: Icons.event_seat,
                    label: '$_selectedSeats seat${_selectedSeats > 1 ? 's' : ''}',
                    isSelected: _selectedSeats > 1,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _buildSeatsSelector(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          controller: _pickupController,
                          label: 'From',
                          hint: 'Select pickup',
                          icon: Icons.location_on,
                          readOnly: true,
                          onTap: () async {
                            final result = await Navigator.push<LocationSearchResult>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LocationSearchPage(
                                  title: 'Select Pickup',
                                  hint: 'Enter pickup location',
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _pickupLocation = result.location;
                                _pickupController.text = result.name;
                              });
                              if (_destinationLocation != null) await _fetchRoute();
                              _mapController.move(result.location, 14);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          controller: _destinationController,
                          label: 'To',
                          hint: 'Select destination',
                          icon: Icons.flag,
                          readOnly: true,
                          onTap: () async {
                            final result = await Navigator.push<LocationSearchResult>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LocationSearchPage(
                                  title: 'Select Destination',
                                  hint: 'Enter destination',
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _destinationLocation = result.location;
                                _destinationController.text = result.name;
                              });
                              if (_pickupLocation != null) await _fetchRoute();
                              _mapController.move(result.location, 14);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.borderGray,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.swap_vert,
                            color: AppColors.silverLight,
                          ),
                          onPressed: _swapLocations,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Map area
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(23.8103, 90.4125),
                  initialZoom: 12,
                  onTap: (tapPosition, point) => _handleMapTap(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.cholo',
                  ),
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4,
                          color: AppColors.pureWhite,
                        ),
                      ],
                    ),
                  if (_pickupLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _pickupLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.successGreen,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  if (_destinationLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _destinationLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.dangerRed,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Search button
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomButton(
                label: 'Search',
                onPressed: _isLoading ? null : _searchRides,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pureWhite : AppColors.cardBlack,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.pureWhite : AppColors.borderGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryBlack : AppColors.silverLight,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyM.copyWith(
                color: isSelected ? AppColors.primaryBlack : AppColors.silverLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatsSelector() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: AppColors.surfaceBlack,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Number of Seats',
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _decrementSeats,
                icon: const Icon(Icons.remove, color: AppColors.silverLight),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Center(
                  child: Text(
                    '$_selectedSeats',
                    style: AppTextStyles.headingL,
                  ),
                ),
              ),
              IconButton(
                onPressed: _incrementSeats,
                icon: const Icon(Icons.add, color: AppColors.silverLight),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomButton(
              label: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
