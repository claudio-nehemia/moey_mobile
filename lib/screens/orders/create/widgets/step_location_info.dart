import 'package:flutter/material.dart';
import 'order_form_components.dart';

class StepLocationInfo extends StatelessWidget {
  final TextEditingController unitNumberController;
  final TextEditingController addressController;
  final TextEditingController additionalInfoController;

  const StepLocationInfo({
    super.key,
    required this.unitNumberController,
    required this.addressController,
    required this.additionalInfoController,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Alamat & Detail Lokasi',
      icon: Icons.location_on_outlined,
      children: [
        FormTextField(
          controller: unitNumberController,
          label: 'Nomor Unit',
          hint: 'Contoh: Tower A - Lantai 12 (Opsional)',
          prefixIcon: Icons.tag_outlined,
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: addressController,
          label: 'Alamat Lengkap Proyek *',
          hint: 'Masukkan alamat lengkap pengiriman/lokasi pengerjaan',
          maxLines: 3,
          prefixIcon: Icons.map_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Alamat proyek wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: additionalInfoController,
          label: 'Catatan Tambahan Customer',
          hint: 'Contoh: Cat dinding kamar warna cream, request survey sore hari (Opsional)',
          maxLines: 2,
          prefixIcon: Icons.chat_bubble_outline_rounded,
        ),
      ],
    );
  }
}
