import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPicker extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final Function(double lat, double lng) onLocationPicked;

  const LocationPicker({
    super.key,
    this.initialLatitude = 51.509364, // Default London
    this.initialLongitude = -0.128928,
    required this.onLocationPicked,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late MapController _mapController;
  late LatLng _currentCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentCenter = LatLng(widget.initialLatitude, widget.initialLongitude);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: 15.0,
            onPositionChanged: (position, hasGesture) {
              if (position.center != null) {
                _currentCenter = position.center!;
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.vendora',
            ),
          ],
        ),
        // Center Pin
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              // Adjust for icon height to pinpoint exactly
              const SizedBox(height: 40), 
            ],
          ),
        ),
        // Select Button
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: ElevatedButton(
            onPressed: () {
              widget.onLocationPicked(
                _currentCenter.latitude,
                _currentCenter.longitude,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
