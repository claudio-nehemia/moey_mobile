import 'package:flutter/material.dart';
import 'order_form_components.dart';

class StepParameterInfo extends StatelessWidget {
  final int? selectedInteriorId;
  final String selectedPriority;
  final TextEditingController surveyDateController;
  final List<dynamic> jenisInteriors;
  final ValueChanged<int?> onInteriorChanged;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback onSelectSurveyDate;

  const StepParameterInfo({
    super.key,
    required this.selectedInteriorId,
    required this.selectedPriority,
    required this.surveyDateController,
    required this.jenisInteriors,
    required this.onInteriorChanged,
    required this.onPriorityChanged,
    required this.onSelectSurveyDate,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Parameter Proyek',
      icon: Icons.tune_rounded,
      children: [
        FormDropdownField<int>(
          label: 'Jenis Interior *',
          value: selectedInteriorId,
          hint: 'Pilih tipe interior',
          items: jenisInteriors.map((item) {
            return DropdownMenuItem<int>(
              value: item['id'],
              child: Text(item['nama_interior']),
            );
          }).toList(),
          onChanged: onInteriorChanged,
          validator: (v) => v == null ? 'Pilih jenis interior' : null,
        ),
        const SizedBox(height: 16),
        FormDropdownField<String>(
          label: 'Tingkat Prioritas *',
          value: selectedPriority,
          hint: 'Pilih tingkat prioritas',
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Rendah (Low)')),
            DropdownMenuItem(value: 'medium', child: Text('Sedang (Medium)')),
            DropdownMenuItem(value: 'high', child: Text('Tinggi (High)')),
          ],
          onChanged: onPriorityChanged,
        ),
        const SizedBox(height: 16),
        FormDatePickerField(
          controller: surveyDateController,
          label: 'Rencana Tanggal Survey',
          hint: 'Pilih tanggal rencana survey',
          onTap: onSelectSurveyDate,
        ),
      ],
    );
  }
}
