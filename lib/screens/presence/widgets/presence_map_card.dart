import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class PresenceMapCard extends StatelessWidget {
  final Position? currentPosition;
  final LatLng? officeLatLng;
  final double officeRadius;
  final bool isWithinGeofence;
  final double distanceToOffice;

  const PresenceMapCard({
    super.key,
    required this.currentPosition,
    required this.officeLatLng,
    required this.officeRadius,
    required this.isWithinGeofence,
    required this.distanceToOffice,
  });

  @override
  Widget build(BuildContext context) {
    if (currentPosition == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '📍 Peta Lokasi & Geofence',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  currentPosition!.latitude,
                  currentPosition!.longitude,
                ),
                initialZoom: 16.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.moey.mobile',
                ),
                if (officeLatLng != null) ...[
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: officeLatLng!,
                        radius: officeRadius,
                        useRadiusInMeter: true,
                        color: isWithinGeofence
                            ? Colors.teal.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderColor: isWithinGeofence ? Colors.teal : Colors.red,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: officeLatLng!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.business_rounded,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        currentPosition!.latitude,
                        currentPosition!.longitude,
                      ),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle_rounded,
                        color: Colors.redAccent,
                        size: 35,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildGeofenceBadge(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGeofenceBadge() {
    if (officeLatLng == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Text(
          '⚠ Koordinat lokasi cabang belum dikonfigurasi di dashboard web.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade900,
          ),
        ),
      );
    }

    if (currentPosition == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          '⏳ Sedang mendeteksi koordinat GPS...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isWithinGeofence ? Colors.teal.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWithinGeofence ? Colors.teal.shade200 : Colors.red.shade200,
        ),
      ),
      child: Text(
        isWithinGeofence
            ? '✓ Anda berada di dalam radius kantor (${distanceToOffice.toStringAsFixed(1)}m)'
            : '✗ Anda berada di luar radius kantor (${distanceToOffice.toStringAsFixed(1)}m, batas: ${officeRadius.toStringAsFixed(0)}m)',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isWithinGeofence ? Colors.teal.shade800 : Colors.red.shade800,
        ),
      ),
    );
  }
}
