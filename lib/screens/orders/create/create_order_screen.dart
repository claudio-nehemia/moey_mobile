import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/order_service.dart';
import '../../../utils/constant.dart';
import 'widgets/wizard_header.dart';
import 'widgets/wizard_nav_buttons.dart';
import 'widgets/step_client_info.dart';
import 'widgets/step_location_info.dart';
import 'widgets/step_parameter_info.dart';
import 'widgets/step_team_mom.dart';

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
  final List<File> _selectedFiles = [];

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
        _surveyDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih file: $e')),
        );
      }
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

  Widget _buildWizardForm() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            WizardHeader(currentStep: _currentStep),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(),
                ),
              ),
            ),
            WizardNavButtons(
              currentStep: _currentStep,
              isSubmitting: _isSubmitting,
              onPrev: _prevStep,
              onNext: _nextStep,
              onSubmit: _submitOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return StepClientInfo(
          key: const ValueKey(0),
          projectNameController: _projectNameController,
          companyNameController: _companyNameController,
          customerNameController: _customerNameController,
          phoneController: _phoneController,
        );
      case 1:
        return StepLocationInfo(
          key: const ValueKey(1),
          unitNumberController: _unitNumberController,
          addressController: _addressController,
          additionalInfoController: _additionalInfoController,
        );
      case 2:
        return StepParameterInfo(
          key: const ValueKey(2),
          selectedInteriorId: _selectedInteriorId,
          selectedPriority: _selectedPriority,
          surveyDateController: _surveyDateController,
          jenisInteriors: _jenisInteriors,
          onInteriorChanged: (val) => setState(() => _selectedInteriorId = val),
          onPriorityChanged: (val) => setState(() => _selectedPriority = val ?? 'medium'),
          onSelectSurveyDate: _selectSurveyDate,
        );
      case 3:
        return StepTeamMom(
          key: const ValueKey(3),
          marketings: _marketings,
          drafters: _drafters,
          desainers: _desainers,
          selectedMarketingIds: _selectedMarketingIds,
          selectedDrafterIds: _selectedDrafterIds,
          selectedDesainerIds: _selectedDesainerIds,
          selectedFiles: _selectedFiles,
          onMarketingChanged: (val) => setState(() => _selectedMarketingIds = val),
          onDrafterChanged: (val) => setState(() => _selectedDrafterIds = val),
          onDesainerChanged: (val) => setState(() => _selectedDesainerIds = val),
          onPickMomFiles: _pickMomFiles,
          onRemoveFile: (index) => setState(() => _selectedFiles.removeAt(index)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
