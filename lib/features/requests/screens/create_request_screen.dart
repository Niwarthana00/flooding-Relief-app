import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sahana/core/theme/app_colors.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? _selectedCategory;
  String _urgencyLevel = 'Medium';
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _familySizeController = TextEditingController(
    text: '4',
  );
  bool _isLoading = false;
  GeoPoint? _currentLocation;
  String _locationText = 'Fetching location...';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food Package', 'icon': Icons.inventory_2_outlined},
    {'name': 'Medical Supplies', 'icon': Icons.medical_services_outlined},
    {'name': 'Clothing & Essentials', 'icon': Icons.checkroom_outlined},
    {'name': 'Shelter Materials', 'icon': Icons.home_work_outlined},
    {'name': 'Cash Assistance', 'icon': Icons.payments_outlined},
    {'name': 'Other', 'icon': Icons.help_outline_rounded},
  ];

  final List<String> _urgencyLevels = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _getAddressFromLatLng(GeoPoint point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          // Construct a readable address
          // e.g. "No 123, Galle Road, Colombo 03, Western Province"
          List<String> addressParts = [];
          if (place.street != null) addressParts.add(place.street!);
          if (place.subLocality != null) addressParts.add(place.subLocality!);
          if (place.locality != null) addressParts.add(place.locality!);
          if (place.administrativeArea != null)
            addressParts.add(place.administrativeArea!);

          _locationText = addressParts.join(', ');
        });
      } else {
        setState(() {
          _locationText =
              'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        _locationText =
            'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _fetchUserLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('location')) {
            final geoPoint = data['location'] as GeoPoint;
            setState(() {
              _currentLocation = geoPoint;
            });
            _getAddressFromLatLng(geoPoint);
          } else {
            setState(() {
              _locationText = 'Location not found. Please update.';
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _locationText = 'Error fetching location';
      });
    }
  }

  Future<void> _updateLocation() async {
    setState(() {
      _locationText = 'Updating location...';
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission permanently denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final geoPoint = GeoPoint(position.latitude, position.longitude);

      setState(() {
        _currentLocation = geoPoint;
      });

      await _getAddressFromLatLng(geoPoint);
    } catch (e) {
      setState(() {
        _locationText = 'Error updating location';
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a request type')),
      );
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }
    if (_currentLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location is required')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('requests').add({
          'userId': user.uid,
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'urgency': _urgencyLevel,
          'familySize': int.tryParse(_familySizeController.text) ?? 1,
          'location': _currentLocation,
          'status': 'Pending',
          'createdAt': FieldValue.serverTimestamp(),
          'userName': user.displayName ?? 'Unknown',
          'address': _locationText, // Save the address text too
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted successfully!')),
          );
          Navigator.pop(context); // Go back to dashboard
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting request: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _familySizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back to Dashboard',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tell us what you need and we'll find help",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request Type
                  const Text(
                    'Request Type *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5, // Wider cards
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category['name'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category['name'];
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.background
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                category['icon'],
                                color: isSelected
                                    ? AppColors.primaryGreen
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category['name'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : AppColors.textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Detailed Description
                  const Text(
                    'Detailed Description *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Please describe your needs in detail...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Urgency Level
                  const Text(
                    'Urgency Level *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _urgencyLevels.map((level) {
                      final isSelected = _urgencyLevel == level;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _urgencyLevel = level;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  level,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Family Size
                  const Text(
                    'Family Size *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _familySizeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter number of family members',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF), // Light blue bg
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Current Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _locationText,
                          style: const TextStyle(color: AppColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _updateLocation,
                          child: Text(
                            'Update Location',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6EE7B7,
                        ), // Light green like image
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
