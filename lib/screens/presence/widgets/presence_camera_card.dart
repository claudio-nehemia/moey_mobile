import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class PresenceCameraCard extends StatelessWidget {
  final File? selfieFile;
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final List<CameraDescription>? cameras;
  final VoidCallback onRetakePhoto;
  final VoidCallback onSwitchCamera;
  final VoidCallback onCaptureImage;

  const PresenceCameraCard({
    super.key,
    required this.selfieFile,
    required this.isCameraInitialized,
    required this.cameraController,
    required this.cameras,
    required this.onRetakePhoto,
    required this.onSwitchCamera,
    required this.onCaptureImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '📸 Verifikasi Selfie Wajah',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: selfieFile != null
              ? _buildSelfiePreview()
              : isCameraInitialized && cameraController != null
                  ? _buildLiveCamera()
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSelfiePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(selfieFile!, fit: BoxFit.cover),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: ElevatedButton.icon(
            onPressed: onRetakePhoto,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Foto Ulang', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveCamera() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: cameraController!.value.previewSize?.height ?? 1080,
                height: cameraController!.value.previewSize?.width ?? 1920,
                child: CameraPreview(cameraController!),
              ),
            ),
          ),
          _buildCameraOverlay(),
          if (cameras != null && cameras!.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.transparent,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(
                      Icons.cameraswitch_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: onSwitchCamera,
                    tooltip: 'Ganti Kamera (Depan / Belakang)',
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 12,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              onPressed: onCaptureImage,
              child: const Icon(Icons.camera_alt, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 160,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
            borderRadius: const BorderRadius.all(Radius.elliptical(80, 100)),
          ),
          child: Center(
            child: Container(
              width: 154,
              height: 194,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                borderRadius: const BorderRadius.all(Radius.elliptical(77, 97)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
