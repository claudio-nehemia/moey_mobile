import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';
import 'order_form_components.dart';

class StepTeamMom extends StatelessWidget {
  final List<dynamic> marketings;
  final List<dynamic> drafters;
  final List<dynamic> desainers;
  final List<int> selectedMarketingIds;
  final List<int> selectedDrafterIds;
  final List<int> selectedDesainerIds;
  final List<File> selectedFiles;
  final ValueChanged<List<int>> onMarketingChanged;
  final ValueChanged<List<int>> onDrafterChanged;
  final ValueChanged<List<int>> onDesainerChanged;
  final VoidCallback onPickMomFiles;
  final ValueChanged<int> onRemoveFile;

  const StepTeamMom({
    super.key,
    required this.marketings,
    required this.drafters,
    required this.desainers,
    required this.selectedMarketingIds,
    required this.selectedDrafterIds,
    required this.selectedDesainerIds,
    required this.selectedFiles,
    required this.onMarketingChanged,
    required this.onDrafterChanged,
    required this.onDesainerChanged,
    required this.onPickMomFiles,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormSection(
          title: 'Penugasan Tim Kerja',
          icon: Icons.people_outline_rounded,
          children: [
            FormMultiSelectField(
              label: 'Kepala Marketing',
              items: marketings,
              selectedIds: selectedMarketingIds,
              placeholder: 'Pilih kepala marketing',
              onSelectedChanged: onMarketingChanged,
            ),
            const SizedBox(height: 16),
            FormMultiSelectField(
              label: 'Surveyor / Drafter',
              items: drafters,
              selectedIds: selectedDrafterIds,
              placeholder: 'Pilih surveyor / drafter',
              onSelectedChanged: onDrafterChanged,
            ),
            const SizedBox(height: 16),
            FormMultiSelectField(
              label: 'Desainer',
              items: desainers,
              selectedIds: selectedDesainerIds,
              placeholder: 'Pilih desainer',
              onSelectedChanged: onDesainerChanged,
            ),
          ],
        ),
        const SizedBox(height: 20),
        FormSection(
          title: 'Minutes of Meeting (MOM)',
          icon: Icons.attachment_rounded,
          children: [
            GestureDetector(
              onTap: onPickMomFiles,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Constants.surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Constants.primaryColor.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.upload_file_outlined,
                        color: Constants.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih file MOM (PDF/Word, bisa banyak)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Constants.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Format file yang didukung: PDF, DOC, DOCX',
                      style: TextStyle(fontSize: 10, color: Constants.textLight),
                    ),
                  ],
                ),
              ),
            ),
            if (selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...List.generate(selectedFiles.length, (index) {
                final file = selectedFiles[index];
                final fileName = file.path.split(RegExp(r'[/\\]')).last;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Constants.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 16, color: Constants.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontSize: 12, color: Constants.textDark, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Constants.errorColor),
                        onPressed: () => onRemoveFile(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ],
    );
  }
}
