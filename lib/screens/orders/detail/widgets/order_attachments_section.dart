import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';

class OrderAttachmentsSection extends StatelessWidget {
  final List<dynamic>? momFiles;
  final Function(String path) onOpenFile;

  const OrderAttachmentsSection({
    super.key,
    required this.momFiles,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.attachment_rounded, size: 18, color: Constants.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Minutes of Meeting (MOM)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Constants.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Constants.borderColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: momFiles == null || momFiles!.isEmpty
                ? const Row(
                    children: [
                      Icon(Icons.insert_drive_file_outlined, size: 16, color: Constants.textMedium),
                      SizedBox(width: 10),
                      Text(
                        'Tidak ada lampiran dokumen MOM',
                        style: TextStyle(
                          fontSize: 12,
                          color: Constants.textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: momFiles!.map((fileObj) {
                      final path = fileObj['path'] as String? ?? '';
                      final fileName = path.split('/').last;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Constants.borderColor),
                        ),
                        child: InkWell(
                          onTap: () => onOpenFile(path),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Constants.primaryColor.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.insert_drive_file_outlined, size: 16, color: Constants.primaryColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Constants.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Constants.primaryColor.withOpacity(0.06),
                                  ),
                                  child: const Icon(Icons.open_in_new_rounded, size: 12, color: Constants.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
