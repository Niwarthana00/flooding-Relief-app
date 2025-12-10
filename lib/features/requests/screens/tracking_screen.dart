import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sahana/core/theme/app_colors.dart';

class TrackingScreen extends StatefulWidget {
  final String requestId;
  final GeoPoint? deliveryLocation;

  const TrackingScreen({
    super.key,
    required this.requestId,
    this.deliveryLocation,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  // GoogleMapController? _mapController; // Removed unused controller
  BitmapDescriptor? _volunteerIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    // You can load custom icons here if you have assets
    // For now we use default markers with different hues
    _volunteerIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueBlue,
    );
    _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueRed,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Request'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final volunteerGeo = data?['volunteerLocation'] as GeoPoint?;

          // Default center: Delivery location or Colombo
          LatLng center = const LatLng(6.9271, 79.8612);
          if (volunteerGeo != null) {
            center = LatLng(volunteerGeo.latitude, volunteerGeo.longitude);
          } else if (widget.deliveryLocation != null) {
            center = LatLng(
              widget.deliveryLocation!.latitude,
              widget.deliveryLocation!.longitude,
            );
          }

          final markers = <Marker>{};

          // Delivery Location Marker (Destination)
          if (widget.deliveryLocation != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('destination'),
                position: LatLng(
                  widget.deliveryLocation!.latitude,
                  widget.deliveryLocation!.longitude,
                ),
                infoWindow: const InfoWindow(title: 'Destination'),
                icon: _destinationIcon ?? BitmapDescriptor.defaultMarker,
              ),
            );
          }

          // Volunteer Location Marker (Vehicle)
          if (volunteerGeo != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('volunteer'),
                position: LatLng(volunteerGeo.latitude, volunteerGeo.longitude),
                infoWindow: const InfoWindow(title: 'Volunteer'),
                icon: _volunteerIcon ?? BitmapDescriptor.defaultMarker,
              ),
            );
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 14.0),
            markers: markers,
            // onMapCreated: (GoogleMapController controller) {
            //   _mapController = controller;
            // },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }
}
