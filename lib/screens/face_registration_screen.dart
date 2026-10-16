import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_recognition_service.dart';
import '../utils/constant.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  bool _isRegistered = false;
  int _totalFaces = 0;
  List<dynamic> _wajahList = [];
  Map<String, dynamic>? _karyawanData;

  Uint8List? _previewBytes;
  String? _previewFileName;

  @override
  void initState() {
    super.initState();
    _loadFaceData();
  }

  Future<void> _loadFaceData() async {
    setState(() => _isLoading = true);
    final res = await _faceService.getFaceStatus();
    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          _isRegistered = res['registered'] == true;
          _totalFaces = (res['total'] as num?)?.toInt() ?? 0;
          _wajahList = res['wajah_list'] ?? [];
          _karyawanData = res['karyawan'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memuat status pendaftaran wajah'),
            backgroundColor: Constants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _previewBytes = bytes;
        _previewFileName = file.name.isNotEmpty
            ? file.name
            : 'face_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: $e'),
          backgroundColor: Constants.errorColor,
        ),
      );
    }
  }

  Future<void> _uploadPreview() async {
    if (_previewBytes == null || _previewFileName == null) return;

    setState(() => _isUploading = true);

    final res = await _faceService.uploadFace(
      bytes: _previewBytes!,
      filename: _previewFileName!,
      direction: 'front',
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Foto wajah berhasil didaftarkan'),
          backgroundColor: Constants.successColor,
        ),
      );
      setState(() {
        _previewBytes = null;
        _previewFileName = null;
      });
      _loadFaceData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mendaftarkan foto wajah'),
          backgroundColor: Constants.errorColor,
        ),
      );
    }
  }

  Future<void> _confirmDeleteFace(int faceId, String faceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Foto Wajah',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus foto wajah master ini ($faceName)?',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Constants.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final res = await _faceService.deleteFace(faceId);
    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Foto wajah berhasil dihapus'),
          backgroundColor: Constants.successColor,
        ),
      );
      _loadFaceData();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal menghapus foto wajah'),
          backgroundColor: Constants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _isRegistered);
      },
      child: Scaffold(
        backgroundColor: Constants.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Pendaftaran Wajah',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Constants.textDark,
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          backgroundColor: Constants.cardColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Constants.textDark),
            onPressed: () => Navigator.pop(context, _isRegistered),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Constants.borderColor, height: 1),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Constants.primaryColor),
              )
            : RefreshIndicator(
                onRefresh: _loadFaceData,
                color: Constants.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      if (_previewBytes != null) ...[
                        _buildPreviewCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                      _buildGuidelinesCard(),
                      const SizedBox(height: 24),
                      _buildMasterFacesSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool registered = _isRegistered;
    final Color badgeColor = registered ? Constants.successColor : Constants.errorColor;
    final IconData badgeIcon = registered ? Icons.verified_user_rounded : Icons.warning_amber_rounded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: badgeColor, width: 6)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(badgeIcon, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          registered ? 'Wajah Sudah Terdaftar' : 'Wajah Belum Terdaftar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            registered ? 'Terdaftar' : 'Belum Terdaftar',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      registered
                          ? 'Wajah Anda telah terverifikasi di sistem absensi dengan $_totalFaces foto master terdaftar.'
                          : 'Anda belum mendaftarkan wajah. Segera daftarkan foto wajah Anda agar dapat melakukan absensi presensi.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Constants.textDark,
                        height: 1.4,
                      ),
                    ),
                    if (_karyawanData != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Karyawan: ${_karyawanData!['nama'] ?? ''} (${_karyawanData!['nik'] ?? ''})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Constants.textMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Constants.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pratinjau Foto Wajah Baru',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Constants.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Constants.textMedium),
                onPressed: _isUploading
                    ? null
                    : () {
                        setState(() {
                          _previewBytes = null;
                          _previewFileName = null;
                        });
                      },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Constants.primaryColor, width: 2),
            ),
            child: ClipOval(
              child: Image.memory(
                _previewBytes!,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Constants.surfaceColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_rounded, color: Constants.primaryColor, size: 36),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          _previewFileName ?? 'Format HEIC/Foto',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Constants.textMedium),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUploading
                      ? null
                      : () {
                          setState(() {
                            _previewBytes = null;
                            _previewFileName = null;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Constants.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batal', style: TextStyle(color: Constants.textMedium)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadPreview,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: Text(_isUploading ? 'Menyimpan...' : 'Simpan Foto Wajah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftarkan Foto Wajah',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Constants.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _isUploading ? null : () => _pickImage(ImageSource.camera),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Constants.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Ambil Foto Selfie',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Constants.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Constants.borderColor),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, color: Constants.textDark, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Pilih dari Galeri',
                        style: TextStyle(
                          color: Constants.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuidelinesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Constants.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Constants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: Constants.accentColor),
              SizedBox(width: 8),
              Text(
                'Panduan Pengambilan Foto Wajah',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Constants.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildGuidelineItem('Pencahayaan terang dan stabil, hindari backlight.'),
          _buildGuidelineItem('Wajah menghadap lurus ke arah kamera (posisi frontal).'),
          _buildGuidelineItem('Jangan menggunakan masker, kacamata hitam, atau penutup wajah.'),
          _buildGuidelineItem('Pastikan hasil foto tajam dan tidak buram.'),
          _buildGuidelineItem('Format didukung: JPG, PNG, WEBP, dan HEIC / HEIF (hingga 10MB).'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Constants.accentColor,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Constants.textMedium,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterFacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Master Wajah Terdaftar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Constants.textDark,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Constants.surfaceColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Constants.borderColor),
              ),
              child: Text(
                '$_totalFaces Foto',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Constants.textMedium,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_wajahList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Constants.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Constants.borderColor, style: BorderStyle.solid),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.face_retouching_off_rounded,
                  size: 40,
                  color: Constants.textLight,
                ),
                SizedBox(height: 12),
                Text(
                  'Belum Ada Foto Wajah Master',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Constants.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Silakan ambil foto selfie untuk mendaftarkan wajah Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Constants.textMedium),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _wajahList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final face = _wajahList[index];
              final String? url = face['url'];
              final String faceName = face['wajah'] ?? 'Foto ${index + 1}';
              final String? date = face['created_at'];

              return Container(
                decoration: BoxDecoration(
                  color: Constants.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Constants.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: url != null && url.isNotEmpty
                                ? Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Constants.primaryColor,
                                        ),
                                      );
                                    },
                                    errorBuilder: (ctx, err, stack) => Container(
                                      color: Constants.surfaceColor,
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          color: Constants.textLight,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Constants.surfaceColor,
                                    child: const Center(
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Constants.textLight,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            color: Constants.cardColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  faceName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Constants.textDark,
                                  ),
                                ),
                                if (date != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Constants.textLight,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => _confirmDeleteFace(face['id'], faceName),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Constants.errorColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
