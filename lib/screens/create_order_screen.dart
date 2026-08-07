import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/order_service.dart';
import '../utils/constant.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final OrderService _orderService = OrderService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _projectNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _unitNumberController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _surveyDateController = TextEditingController();

  // Selected values
  int? _selectedInteriorId;
  String _selectedPriority = 'medium';
  List<int> _selectedMarketingIds = [];
  List<int> _selectedDrafterIds = [];
  List<int> _selectedDesainerIds = [];
  List<File> _selectedFiles = [];

  // Options from API
  List<dynamic> _marketings = [];
  List<dynamic> _drafters = [];
  List<dynamic> _desainers = [];
  List<dynamic> _jenisInteriors = [];

  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Wizard Steps
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _companyNameController.dispose();
    _customerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _unitNumberController.dispose();
    _additionalInfoController.dispose();
    _surveyDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchFormData() async {
    try {
      final data = await _orderService.getCreateFormData();
      setState(() {
        _marketings = data['marketings'] ?? [];
        _drafters = data['drafters'] ?? [];
        _desainers = data['desainers'] ?? [];
        _jenisInteriors = data['jenis_interiors'] ?? [];
        _isLoadingData = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _selectSurveyDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Constants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Constants.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _surveyDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickMomFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<File> pickedFiles = result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
        setState(() {
          _selectedFiles.addAll(pickedFiles);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e')),
      );
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final Map<String, String> fields = {
        'nama_project': _projectNameController.text.trim(),
        'company_name': _companyNameController.text.trim(),
        'customer_name': _customerNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'alamat': _addressController.text.trim(),
        'jenis_interior_id': _selectedInteriorId.toString(),
        'priority_level': _selectedPriority,
      };

      if (_unitNumberController.text.isNotEmpty) {
        fields['nomor_unit'] = _unitNumberController.text.trim();
      }
      if (_additionalInfoController.text.isNotEmpty) {
        fields['customer_additional_info'] = _additionalInfoController.text.trim();
      }
      if (_surveyDateController.text.isNotEmpty) {
        fields['tanggal_survey'] = _surveyDateController.text.trim();
      }

      final List<int> userIds = [];
      userIds.addAll(_selectedMarketingIds);
      userIds.addAll(_selectedDrafterIds);
      userIds.addAll(_selectedDesainerIds);

      await _orderService.createOrder(
        fields,
        momFilePaths: _selectedFiles.map((f) => f.path).toList(),
        userIds: userIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order baru berhasil dibuat!'),
            backgroundColor: Constants.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Constants.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate first card inputs
      if (_projectNameController.text.trim().isEmpty ||
          _companyNameController.text.trim().isEmpty ||
          _customerNameController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lengkapi kolom bertanda * terlebih dahulu'),
            backgroundColor: Constants.errorColor,
          ),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validate second card inputs
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alamat proyek wajib diisi'),
            backgroundColor: Constants.errorColor,
          ),
        );
        return;
      }
    } else if (_currentStep == 2) {
      // Validate third card inputs
      if (_selectedInteriorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih jenis interior terlebih dahulu'),
            backgroundColor: Constants.errorColor,
          ),
        );
        return;
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Buat Order Baru',
          style: TextStyle(color: Constants.textDark, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        backgroundColor: Constants.cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Constants.textDark),
        shape: const Border(
          bottom: BorderSide(color: Constants.borderColor, width: 1),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildWizardForm(),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Constants.errorColor),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan sistem',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Constants.textDark, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoadingData = true;
                });
                _fetchFormData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardHeader() {
    final stepLabels = ['Klien', 'Alamat', 'Parameter', 'Tim & File'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: List.generate(4, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          final color = isCompleted
              ? Constants.successColor
              : isActive
                  ? Constants.primaryColor
                  : Constants.textLight.withOpacity(0.4);

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : color,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: isActive ? 6 : 1.5),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepLabels[index],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? Constants.textDark : Constants.textMedium,
                      ),
                    ),
                  ],
                ),
                if (index < 3)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        height: 2,
                        color: isCompleted ? Constants.successColor : Constants.borderColor,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWizardForm() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildWizardHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildFormSection(
          key: const ValueKey(0),
          title: 'Informasi Proyek & Klien',
          icon: Icons.person_outline_rounded,
          children: [
            _buildTextField(
              controller: _projectNameController,
              label: 'Nama Proyek *',
              hint: 'Contoh: Renovasi Apartemen Kemang',
              prefixIcon: Icons.assignment_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama proyek wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _companyNameController,
              label: 'Nama Perusahaan / Developer *',
              hint: 'Contoh: PT. Agung Podomoro',
              prefixIcon: Icons.business_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama perusahaan wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _customerNameController,
              label: 'Nama Customer *',
              hint: 'Contoh: Bpk. Claudio Nehemia',
              prefixIcon: Icons.badge_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nama customer wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Nomor Telepon Customer *',
              hint: 'Contoh: 08123456789',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_android_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nomor telepon wajib diisi' : null,
            ),
          ],
        );
      case 1:
        return _buildFormSection(
          key: const ValueKey(1),
          title: 'Alamat & Detail Lokasi',
          icon: Icons.location_on_outlined,
          children: [
            _buildTextField(
              controller: _unitNumberController,
              label: 'Nomor Unit',
              hint: 'Contoh: Tower A - Lantai 12 (Opsional)',
              prefixIcon: Icons.tag_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Alamat Lengkap Proyek *',
              hint: 'Masukkan alamat lengkap pengiriman/lokasi pengerjaan',
              maxLines: 3,
              prefixIcon: Icons.map_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Alamat proyek wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _additionalInfoController,
              label: 'Catatan Tambahan Customer',
              hint: 'Contoh: Cat dinding kamar warna cream, request survey sore hari (Opsional)',
              maxLines: 2,
              prefixIcon: Icons.chat_bubble_outline_rounded,
            ),
          ],
        );
      case 2:
        return _buildFormSection(
          key: const ValueKey(2),
          title: 'Parameter Proyek',
          icon: Icons.tune_rounded,
          children: [
            _buildDropdownField<int>(
              label: 'Jenis Interior *',
              value: _selectedInteriorId,
              hint: 'Pilih tipe interior',
              items: _jenisInteriors.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text(item['nama_interior']),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedInteriorId = val),
              validator: (v) => v == null ? 'Pilih jenis interior' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdownField<String>(
              label: 'Tingkat Prioritas *',
              value: _selectedPriority,
              hint: 'Pilih tingkat prioritas',
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Rendah (Low)')),
                DropdownMenuItem(value: 'medium', child: Text('Sedang (Medium)')),
                DropdownMenuItem(value: 'high', child: Text('Tinggi (High)')),
              ],
              onChanged: (val) => setState(() => _selectedPriority = val ?? 'medium'),
            ),
            const SizedBox(height: 16),
            _buildDatePickerField(
              controller: _surveyDateController,
              label: 'Rencana Tanggal Survey',
              hint: 'Pilih tanggal rencana survey',
              onTap: _selectSurveyDate,
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            _buildFormSection(
              key: const ValueKey(3),
              title: 'Penugasan Tim Kerja',
              icon: Icons.people_outline_rounded,
              children: [
                _buildMultiSelectField(
                  label: 'Kepala Marketing',
                  items: _marketings,
                  selectedIds: _selectedMarketingIds,
                  placeholder: 'Pilih kepala marketing',
                  onSelectedChanged: (val) => setState(() => _selectedMarketingIds = val),
                ),
                const SizedBox(height: 16),
                _buildMultiSelectField(
                  label: 'Surveyor / Drafter',
                  items: _drafters,
                  selectedIds: _selectedDrafterIds,
                  placeholder: 'Pilih surveyor / drafter',
                  onSelectedChanged: (val) => setState(() => _selectedDrafterIds = val),
                ),
                const SizedBox(height: 16),
                _buildMultiSelectField(
                  label: 'Desainer',
                  items: _desainers,
                  selectedIds: _selectedDesainerIds,
                  placeholder: 'Pilih desainer',
                  onSelectedChanged: (val) => setState(() => _selectedDesainerIds = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFormSection(
              key: const ValueKey(4),
              title: 'Minutes of Meeting (MOM)',
              icon: Icons.attachment_rounded,
              children: [
                GestureDetector(
                  onTap: _pickMomFiles,
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
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...List.generate(_selectedFiles.length, (index) {
                    final file = _selectedFiles[index];
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
                            onPressed: () {
                              setState(() {
                                _selectedFiles.removeAt(index);
                              });
                            },
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
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationButtons() {
    final isLastStep = _currentStep == 3;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Constants.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Constants.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Sebelumnya', style: TextStyle(color: Constants.textMedium, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : (isLastStep ? _submitOrder : _nextStep),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Constants.primaryColor.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isLastStep ? 'Simpan Order' : 'Lanjutkan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required Key key,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      key: key,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hint,
    String? Function(T?)? validator,
  }) {
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
          hint: hint != null ? Text(hint, style: const TextStyle(color: Constants.textLight, fontSize: 13)) : null,
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

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
  }) {
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

  Widget _buildMultiSelectField({
    required String label,
    required List<dynamic> items,
    required List<int> selectedIds,
    required String placeholder,
    required Function(List<int>) onSelectedChanged,
  }) {
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
          onTap: () => _showMultiSelectBottomSheet(
            label: label,
            items: items,
            selectedIds: selectedIds,
            onSelectedChanged: onSelectedChanged,
          ),
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

  void _showMultiSelectBottomSheet({
    required String label,
    required List<dynamic> items,
    required List<int> selectedIds,
    required Function(List<int>) onSelectedChanged,
  }) {
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
