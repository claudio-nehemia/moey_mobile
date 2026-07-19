import 'package:safe_device/safe_device.dart';
import 'package:flutter/material.dart';

class SecurityService {
  /// Checks if the device is using a Fake GPS / Mock Location.
  /// Shows a blocking warning dialog if detected and returns true.
  /// Returns false if mock location is not detected or on error.
  static Future<bool> checkMockLocation(BuildContext context) async {
    try {
      bool isMockLocation = await SafeDevice.isMockLocation;
      if (isMockLocation) {
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.security, color: Colors.red, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Keamanan Terdeteksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Aplikasi mendeteksi penggunaan Lokasi Palsu (Mock Location/Fake GPS). Mohon matikan fitur tersebut untuk menggunakan layanan presensi ini.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error checking mock location: $e');
    }
    return false;
  }
}
