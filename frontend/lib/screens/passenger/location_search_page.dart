import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';

class LocationSearchResult {
  final String name;
  final LatLng location;

  LocationSearchResult({required this.name, required this.location});
}

class LocationSearchPage extends StatefulWidget {
  final String title;
  final String hint;

  const LocationSearchPage({
    super.key,
    required this.title,
    required this.hint,
  });

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length > 2) {
        _searchLocations(query);
      } else {
        setState(() => _results = []);
      }
    });
  }

  Future<void> _searchLocations(String query) async {
    print('Searching for: $query');
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=10', 
        ),
        headers: {'User-Agent': 'CholoApp'},
      );

      print('Search response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Results found: ${data.length}');
        setState(() {
          _results = data;
        });
      } else {
        print('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        title: Text(widget.title, style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.bodyL.copyWith(color: AppColors.silverMid),
                prefixIcon: const Icon(Icons.search, color: AppColors.silverLight),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pureWhite),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.silverLight),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      ),
                filled: true,
                fillColor: AppColors.cardBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.length < 3 
                          ? 'Type at least 3 characters to search' 
                          : 'No results found',
                      style: AppTextStyles.bodyM.copyWith(color: AppColors.silverMid),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (context, index) => const Divider(color: AppColors.borderGray, height: 1),
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final displayName = item['display_name'];
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: AppColors.silverLight),
                        title: Text(
                          displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyM.copyWith(color: AppColors.pureWhite),
                        ),
                        subtitle: Text(
                          '${item['type']} • ${item['class']}',
                          style: AppTextStyles.bodyS.copyWith(color: AppColors.silverMid),
                        ),
                        onTap: () {
                          final lat = double.parse(item['lat']);
                          final lon = double.parse(item['lon']);
                          Navigator.pop(
                            context,
                            LocationSearchResult(
                              name: displayName.split(',')[0], // Take the first part of the address as name
                              location: LatLng(lat, lon),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
