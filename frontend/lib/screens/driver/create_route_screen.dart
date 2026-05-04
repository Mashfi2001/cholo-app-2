import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_input_field.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';

class CreateRouteScreen extends StatefulWidget {
  final dynamic ride;

  const CreateRouteScreen({super.key, this.ride});

  @override
  State<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends State<CreateRouteScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _totalSeats = 4;
  dynamic _vehicleInfo;
  bool _isLoading = false;
  bool _isEditing = false;

  LatLng? _originLocation;
  LatLng? _destinationLocation;
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;
  int _estimatedFare = 0;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.ride != null;
    _loadVehicleInfo();
    
    if (_isEditing) {
      _originController.text = widget.ride['origin'] ?? '';
      _destinationController.text = widget.ride['destination'] ?? '';
      _totalSeats = widget.ride['totalSeats'] ?? 4;
      
      if (widget.ride['departureTime'] != null) {
        final dt = DateTime.parse(widget.ride['departureTime']);
        _selectedDate = dt;
        _selectedTime = TimeOfDay.fromDateTime(dt);
      }
      
      // Load stops if any
      final stops = widget.ride['stops'] as List? ?? [];
      for (final stop in stops) {
        _stopControllers.add(TextEditingController(text: stop.toString()));
      }

      if (widget.ride['originLat'] != null && widget.ride['originLng'] != null) {
        _originLocation = LatLng(widget.ride['originLat'].toDouble(), widget.ride['originLng'].toDouble());
      }
      if (widget.ride['destinationLat'] != null && widget.ride['destinationLng'] != null) {
        _destinationLocation = LatLng(widget.ride['destinationLat'].toDouble(), widget.ride['destinationLng'].toDouble());
      }
      _distanceKm = widget.ride['routeDistanceKm']?.toDouble() ?? 0.0;
      _estimatedFare = widget.ride['farePerSeat']?.toInt() ?? 0;
      if (_originLocation != null && _destinationLocation != null) {
        _fetchRoute();
      }
    }
  }

  Future<void> _loadVehicleInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/drivers/${Session.userId}/vehicle'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _vehicleInfo = jsonDecode(response.body)['vehicle'];
        });
      }
    } catch (e) {
      print('Error loading vehicle: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  Future<void> _saveRoute() async {
    if (_originController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter origin and destination',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.warningAmber,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final departureDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final stops = _stopControllers
          .map((c) => c.text)
          .where((s) => s.isNotEmpty)
          .toList();

      final body = {
        'driverId': Session.userId,
        'origin': _originController.text,
        'destination': _destinationController.text,
        'originLat': _originLocation?.latitude,
        'originLng': _originLocation?.longitude,
        'destinationLat': _destinationLocation?.latitude,
        'destinationLng': _destinationLocation?.longitude,
        'routeDistanceKm': _distanceKm,
        'stops': stops,
        'departureTime': departureDateTime.toIso8601String(),
        'totalSeats': _totalSeats,
      };

      final response = _isEditing
          ? await http.put(
              Uri.parse('$backendUrl/api/rides/${widget.ride['id']}'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
          : await http.post(
              Uri.parse('$backendUrl/api/rides'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Route updated!' : 'Route created!',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Failed to save route',
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelRoute() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
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
            const Icon(
              Icons.delete_forever,
              color: AppColors.dangerRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Cancel Route?',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 8),
            Text(
              'This will cancel the route and notify any booked passengers.',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Yes, Cancel Route',
              variant: CustomButtonVariant.danger,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Keep Route',
              variant: CustomButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/api/rides/${widget.ride['id']}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Route cancelled',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ?? 'Failed to cancel route',
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMapTap(LatLng point) async {
    if (_originLocation == null) {
      setState(() {
        _originLocation = point;
        _originController.text = "Loading...";
      });
      final locationName = await _reverseGeocode(point);
      setState(() => _originController.text = locationName);
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
        _originLocation = point;
        _destinationLocation = null;
        _originController.text = "Loading...";
        _destinationController.clear();
        _routePoints = [];
        _distanceKm = 0;
        _estimatedFare = 0;
      });
      final locationName = await _reverseGeocode(point);
      setState(() => _originController.text = locationName);
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
    if (_originLocation == null || _destinationLocation == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${_originLocation!.longitude},${_originLocation!.latitude};${_destinationLocation!.longitude},${_destinationLocation!.latitude}?overview=full&geometries=geojson',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = coordinates
                .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
                .toList();
            _distanceKm = (route['distance'] as num).toDouble() / 1000.0;
          });
          _calculateFareEstimate();
        }
      }
    } catch (e) {
      print('Route fetching error: $e');
    }
  }

  Future<void> _calculateFareEstimate() async {
    if (_distanceKm <= 0) return;
    
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/fares/estimate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'routeDistanceKm': _distanceKm,
          'seats': _totalSeats,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _estimatedFare = data['unitPassengerFare'] ?? 0;
        });
      }
    } catch (e) {
      print('Fare estimation error: $e');
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    for (final controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
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
                    _isEditing ? 'Edit Route' : 'Set Your Route',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Origin field
              CustomInputField(
                controller: _originController,
                label: 'Starting Point',
                icon: Icons.location_on,
              ),

              const SizedBox(height: 16),

              // Stops
              ..._buildStopFields(),

              // Add stop button
              GestureDetector(
                onTap: _addStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.silverMid,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add Stop',
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.silverMid,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              
              Text(
                'Tap on map to set route',
                style: AppTextStyles.caption.copyWith(color: AppColors.silverMid),
              ),
              const SizedBox(height: 8),
              
              // Map for selection
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
                      if (_originLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _originLocation!,
                              width: 30,
                              height: 30,
                              child: const Icon(Icons.location_on, color: AppColors.successGreen, size: 30),
                            ),
                          ],
                        ),
                      if (_destinationLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _destinationLocation!,
                              width: 30,
                              height: 30,
                              child: const Icon(Icons.location_on, color: AppColors.dangerRed, size: 30),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Destination field
              CustomInputField(
                controller: _destinationController,
                label: 'Destination',
                icon: Icons.flag,
              ),

              const SizedBox(height: 24),

              // Trip details card
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip Details',
                      style: AppTextStyles.headingL.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 20),

                    // Date picker
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      onTap: _selectDate,
                    ),

                    const SizedBox(height: 16),

                    // Time picker
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Departure Time',
                      value: '${_selectedTime.hour % 12 == 0 ? 12 : _selectedTime.hour % 12}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.hour >= 12 ? 'PM' : 'AM'}',
                      onTap: _selectTime,
                    ),

                    const SizedBox(height: 16),

                    // Estimated Fare (Read only)
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: AppColors.silverMid,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Fare per seat',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _estimatedFare > 0 ? 'BDT $_estimatedFare' : 'Calculating...',
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Total seats stepper
                    Row(
                      children: [
                        const Icon(
                          Icons.event_seat,
                          color: AppColors.silverMid,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total seats',
                            style: AppTextStyles.bodyM,
                          ),
                        ),
                        Row(
                          children: [
                            _buildStepperButton(
                              icon: Icons.remove,
                              onTap: () {
                                if (_totalSeats > 1) {
                                  setState(() => _totalSeats--);
                                }
                              },
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '$_totalSeats',
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _buildStepperButton(
                              icon: Icons.add,
                              onTap: () {
                                if (_totalSeats < 8) {
                                  setState(() => _totalSeats++);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Vehicle info row
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: AppColors.silverLight,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _vehicleInfo?['model'] ?? 'Your Vehicle',
                            style: AppTextStyles.bodyL.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _vehicleInfo?['plateNumber'] ?? 'Not set',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to change vehicle
                      },
                      child: Text(
                        'Change →',
                        style: AppTextStyles.labelBold.copyWith(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              CustomButton(
                label: _isEditing ? 'Update Route' : 'Save Route',
                onPressed: _isLoading ? null : _saveRoute,
                isLoading: _isLoading,
              ),

              // Cancel button (only when editing)
              if (_isEditing) ...[
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Cancel Route',
                  variant: CustomButtonVariant.danger,
                  onPressed: _isLoading ? null : _cancelRoute,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStopFields() {
    return _stopControllers.asMap().entries.map((entry) {
      final index = entry.key;
      final controller = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: CustomInputField(
                controller: controller,
                label: 'Stop ${index + 1}',
                icon: Icons.place,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _removeStop(index),
              icon: const Icon(Icons.close, color: AppColors.silverMid),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.silverMid, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.silverMid,
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Icon(icon, color: AppColors.silverLight, size: 18),
      ),
    );
  }
}
