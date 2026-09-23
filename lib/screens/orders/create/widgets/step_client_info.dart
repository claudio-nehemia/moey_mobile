import 'package:flutter/material.dart';
import 'order_form_components.dart';

class StepClientInfo extends StatelessWidget {
  final TextEditingController projectNameController;
  final TextEditingController companyNameController;
  final TextEditingController customerNameController;
  final TextEditingController phoneController;

  const StepClientInfo({
    super.key,
    required this.projectNameController,
    required this.companyNameController,
    required this.customerNameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Informasi Proyek & Klien',
      icon: Icons.person_outline_rounded,
      children: [
        FormTextField(
          controller: projectNameController,
          label: 'Nama Proyek *',
          hint: 'Contoh: Renovasi Apartemen Kemang',
          prefixIcon: Icons.assignment_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama proyek wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: companyNameController,
          label: 'Nama Perusahaan / Developer *',
          hint: 'Contoh: PT. Agung Podomoro',
          prefixIcon: Icons.business_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama perusahaan wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: customerNameController,
          label: 'Nama Customer *',
          hint: 'Contoh: Bpk. Claudio Nehemia',
          prefixIcon: Icons.badge_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama customer wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        FormTextField(
          controller: phoneController,
          label: 'Nomor Telepon Customer *',
          hint: 'Contoh: 08123456789',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_android_outlined,
          validator: (v) => v == null || v.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
        ),
      ],
    );
  }
}
