import 'package:flutter/material.dart';
import '../../../../utils/constant.dart';

class FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Constants.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Constants.textDark, letterSpacing: -0.3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Constants.borderColor),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const FormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Constants.textMedium)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: Constants.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Constants.textLight, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Constants.surfaceColor,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: Constants.textMedium) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.primaryColor, width: 1),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class FormDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? Function(T?)? validator;

  const FormDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Constants.textMedium)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: Constants.textDark),
          hint: hint != null ? Text(hint!, style: const TextStyle(color: Constants.textLight, fontSize: 13)) : null,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: Constants.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.primaryColor, width: 1),
            ),
            errorStyle: const TextStyle(fontSize: 10),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class FormDatePickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback onTap;

  const FormDatePickerField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Constants.textMedium)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: const TextStyle(fontSize: 13, color: Constants.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Constants.textLight, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Constants.surfaceColor,
            suffixIcon: const Icon(Icons.calendar_today, size: 16, color: Constants.textMedium),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Constants.primaryColor, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class FormMultiSelectField extends StatelessWidget {
  final String label;
  final List<dynamic> items;
  final List<int> selectedIds;
  final String placeholder;
  final Function(List<int>) onSelectedChanged;

  const FormMultiSelectField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedIds,
    required this.placeholder,
    required this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedNames = items
        .where((item) => selectedIds.contains(item['id']))
        .map((item) => item['name'] as String)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Constants.textMedium,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _showMultiSelectBottomSheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Constants.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Constants.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedNames.isEmpty
                      ? Text(
                          placeholder,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Constants.textLight,
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: selectedNames.map((name) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Constants.primaryColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Constants.primaryColor.withOpacity(0.15)),
                              ),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Constants.primaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Constants.textMedium,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showMultiSelectBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<int> tempSelectedIds = List.from(selectedIds);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label.replaceAll(' *', ''),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Constants.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onSelectedChanged(tempSelectedIds);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Selesai',
                            style: TextStyle(
                              color: Constants.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Constants.borderColor),
                  Expanded(
                    child: items.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Tidak ada anggota tim yang tersedia',
                                style: TextStyle(color: Constants.textMedium, fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final id = item['id'] as int;
                              final name = item['name'] as String;
                              final email = item['email'] as String;
                              final isSelected = tempSelectedIds.contains(id);

                              return CheckboxListTile(
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Constants.textDark,
                                  ),
                                ),
                                subtitle: Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Constants.textMedium,
                                  ),
                                ),
                                value: isSelected,
                                activeColor: Constants.primaryColor,
                                controlAffinity: ListTileControlAffinity.trailing,
                                onChanged: (bool? val) {
                                  setModalState(() {
                                    if (val == true) {
                                      tempSelectedIds.add(id);
                                    } else {
                                      tempSelectedIds.remove(id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
