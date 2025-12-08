import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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

          final markers = <Marker>[];

          // Delivery Location Marker (Destination)
          if (widget.deliveryLocation != null) {
            markers.add(
              Marker(
                point: LatLng(
                  widget.deliveryLocation!.latitude,
                  widget.deliveryLocation!.longitude,
                ),
                width: 80,
                height: 80,
                child: const Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 40),
                    Text(
                      'Destination',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Volunteer Location Marker (Vehicle)
          if (volunteerGeo != null) {
            markers.add(
              Marker(
                point: LatLng(volunteerGeo.latitude, volunteerGeo.longitude),
                width: 80,
                height: 80,
                child: const Icon(
                  Icons.directions_car, // Vehicle Icon
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            );
          }

          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sahana',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
