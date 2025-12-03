import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingScreen extends StatefulWidget {
  final String requestId;
  final GeoPoint deliveryLocation;

  const TrackingScreen({
    super.key,
    required this.requestId,
    required this.deliveryLocation,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _volunteerIcon;
  BitmapDescriptor? _destinationIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    // Using default markers with different colors for now
    setState(() {
      _volunteerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
      _destinationIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live Tracking',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final volunteerLoc = data?['volunteerLocation'] as GeoPoint?;

          // Create markers
          final markers = <Marker>{};

          // Destination Marker (Beneficiary)
          markers.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(
                widget.deliveryLocation.latitude,
                widget.deliveryLocation.longitude,
              ),
              icon: _destinationIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: const InfoWindow(title: 'My Location'),
            ),
          );

          // Volunteer Marker
          if (volunteerLoc != null) {
            markers.add(
              Marker(
                markerId: const MarkerId('volunteer'),
                position: LatLng(volunteerLoc.latitude, volunteerLoc.longitude),
                icon: _volunteerIcon ?? BitmapDescriptor.defaultMarker,
                infoWindow: const InfoWindow(title: 'Volunteer'),
              ),
            );
          }

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.deliveryLocation.latitude,
                widget.deliveryLocation.longitude,
              ),
              zoom: 14,
            ),
            markers: markers,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          );
        },
      ),
    );
  }
}
