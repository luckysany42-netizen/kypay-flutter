import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'package:kypay/models/user_model.dart';
import 'dart:io';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _bioController     = TextEditingController();
  final _jobController     = TextEditingController();
  final _companyController = TextEditingController();

  bool    _loading       = false;
  bool    _avatarLoading = false;
  String? _successMsg;
  String? _errorMsg;
  File?   _pickedImage; // preview lokal sebelum upload

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      final u = state.user;
      _nameController.text    = u.name;
      _phoneController.text   = u.phone    ?? '';
      _bioController.text     = u.bio      ?? '';       // ✅ sudah benar
      _jobController.text     = u.jobTitle ?? '';       // ✅ sudah benar
      _companyController.text = u.company  ?? '';       // ✅ sudah benar
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _jobController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  // ── Pilih & upload avatar ─────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source:       ImageSource.gallery,
      maxWidth:     800,
      maxHeight:    800,
      imageQuality: 60, // Lebih rendah untuk kompatibilitas dengan HEIC/WebP
    );
    if (picked == null) return;

    setState(() {
      _pickedImage   = File(picked.path);
      _avatarLoading = true;
      _errorMsg      = null;
      _successMsg    = null;
    });

    try {
      final imageFile = File(picked.path);
      
      // Validasi file exist
      if (!await imageFile.exists()) {
        throw Exception('File tidak ditemukan');
      }
      
      // Validasi ukuran file original (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Ukuran file terlalu besar (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB). Max 5MB');
      }

      // ✅ COMPRESS IMAGE sebelum upload
      final compressedFile = await _compressImage(imageFile);
      final compressedSize = await compressedFile.length();

      // Generate unique filename dengan timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'avatar_$timestamp.jpg';

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          compressedFile.path,
          filename: filename,
          contentType: DioMediaType.parse('image/jpeg'),
        ),
      });

      // ignore: avoid_print
      print('📤 Uploading avatar: $filename');
      // ignore: avoid_print
      print('   Original: ${(fileSize / 1024).toStringAsFixed(2)}KB → Compressed: ${(compressedSize / 1024).toStringAsFixed(2)}KB');
      
      // Ambil token untuk header Authorization
      final token = await ApiService.getToken();
      
      final response = await ApiService.dio.post(
        '/profile/avatar',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Token $token',
            'Accept': 'application/json',
          },
        ),
      );
      
      // ignore: avoid_print
      print('✅ Avatar uploaded successfully');
      // ignore: avoid_print
      print('📋 Response: ${response.data}');
      
      // Update user data langsung dari response
      final responseData = response.data;
      final userData = responseData['user'];

      if (userData != null && mounted) {
        final currentUser = (context.read<AuthBloc>().state as AuthAuthenticated).user;
        
        // Avatar dari response: bisa dari user.avatar atau top-level avatar
        final avatarFilename = userData['avatar'] ?? responseData['avatar'];
        
        // ignore: avoid_print
        print('🖼️  [Avatar] Filename dari response: $avatarFilename');
        
        final updatedUser = UserModel(
          id:        currentUser.id,
          name:      currentUser.name,
          email:     currentUser.email,
          phone:     currentUser.phone,
          avatar:    avatarFilename, // ← filename dari response (contoh: "60f7e9c.jpg")
          role:      currentUser.role,
          apiToken:  currentUser.apiToken,
          jobTitle:  currentUser.jobTitle,
          company:   currentUser.company,
          bio:       currentUser.bio,
        );
        
        // ignore: avoid_print
        print('🖼️  [Avatar] Updated avatarUrl: ${updatedUser.avatarUrl}');
        
        // ignore: use_build_context_synchronously
        context.read<AuthBloc>().add(UpdateUserData(updatedUser));
        
        setState(() {
          _successMsg = 'Foto profil berhasil diperbarui!';
          _pickedImage = null;
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error uploading avatar: $e');
      
      String errorMsg = 'Gagal mengunggah foto profil';
      
      // Parse error message
      if (e is DioException) {
        if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          errorMsg = data['message'] ?? 
                    data['error'] ?? 
                    'Gagal mengunggah foto. Coba lagi.';
        } else {
          errorMsg = 'Error: ${e.response?.statusCode} - ${e.message}';
        }
      } else {
        errorMsg = e.toString();
      }
      
      if (mounted) {
        setState(() { 
          _errorMsg = errorMsg; 
          _pickedImage = null; 
        });
      }
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  // ── Simpan perubahan profil ───────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _successMsg = null; _errorMsg = null; });
    try {
      await ApiService.dio.post('/profile/update', data: {
        'name':      _nameController.text.trim(),
        'phone':     _phoneController.text.trim(),
        'bio':       _bioController.text.trim(),
        'job_title': _jobController.text.trim(),
        'company':   _companyController.text.trim(),
      });
      
      // Update user data langsung tanpa verify_token
      // ignore: use_build_context_synchronously
      final state = context.read<AuthBloc>().state;
      if (state is AuthAuthenticated) {
        final user = state.user;
        final updatedUser = UserModel(
          id:        user.id,
          name:      _nameController.text.trim(),
          email:     user.email,
          phone:     _phoneController.text.trim(),
          avatar:    user.avatar, // ← field avatar (bukan avatarUrl yang getter!)
          role:      user.role,
          apiToken:  user.apiToken,
          jobTitle:  _jobController.text.trim(),
          company:   _companyController.text.trim(),
          bio:       _bioController.text.trim(),
        );
        
        // ignore: avoid_print
        print('✅ [Profile] Updated user: ${updatedUser.name} (avatar: ${updatedUser.avatar})');
        // ignore: use_build_context_synchronously
        context.read<AuthBloc>().add(UpdateUserData(updatedUser));
      }
      if (mounted) setState(() => _successMsg = 'Profil berhasil diperbarui!');
    } catch (e) {
      final data = (e as dynamic).response?.data;
      final msg  = data?['errors']?['name']  ??
                  data?['errors']?['phone'] ??
                  data?['message']          ??
                  'Gagal memperbarui profil.';
      if (mounted) setState(() => _errorMsg = msg.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Avatar dengan tombol kamera ────────────────
                  Center(
                    child: Stack(
                      children: [
                        // Foto / inisial
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              //ignore: deprecated_member_use
                              color: const Color(0xFF1a56db).withOpacity(0.4),  
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _avatarLoading
                                ? Container(
                                    color: const Color(0xFF1a3a6b),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Color(0xFF1a56db),
                                          strokeWidth: 2),
                                    ),
                                  )
                                : _pickedImage != null
                                    // Preview file lokal
                                    ? Image.file(_pickedImage!,
                                        fit: BoxFit.cover,
                                        width: 90, height: 90)
                                    : user?.avatarUrl != null
                                        // Avatar dari server
                                        ? Image.network(
                                            user!.avatarUrl!,
                                            fit: BoxFit.cover,
                                            width: 90, height: 90,
                                            loadingBuilder: (_, child, progress) =>
                                                progress == null
                                                    ? child
                                                    : Container(
                                                        color: const Color(0xFF1a3a6b),
                                                        child: const Center(
                                                          child: CircularProgressIndicator(
                                                              color: Color(0xFF1a56db),
                                                              strokeWidth: 2),
                                                        ),
                                                      ),
                                            errorBuilder: (_, __, ___) =>
                                                _defaultAvatar(user.name),
                                          )
                                        // Default inisial
                                        : _defaultAvatar(user?.name ?? 'K'),
                          ),
                        ),

                        // Tombol kamera pojok kanan bawah
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _avatarLoading ? null : _pickAndUploadAvatar,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1a56db),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF0f1b35), width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),
                  Center(
                    child: Text('Ketuk ikon kamera untuk ganti foto',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11)),
                  ),

                  const SizedBox(height: 28),

                  // ── Informasi Dasar ────────────────────────────
                  _sectionHeader('INFORMASI DASAR', const Color(0xFF0891b2)),
                  _buildField(
                    controller: _nameController,
                    label:      'Nama Lengkap',
                    icon:       Icons.person_outline,
                    validator:  (v) => v == null || v.trim().isEmpty
                        ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller:   _phoneController,
                    label:        'No. Telepon',
                    icon:         Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 20),

                  // ── Informasi Pekerjaan ────────────────────────
                  _sectionHeader('INFORMASI PEKERJAAN', const Color(0xFFd97706)),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _jobController,
                          label:      'Jabatan',
                          icon:       Icons.work_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _companyController,
                          label:      'Perusahaan',
                          icon:       Icons.business_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Tentang Kamu ───────────────────────────────
                  _sectionHeader('TENTANG KAMU', const Color(0xFF9b59b6)),
                  _buildField(
                    controller: _bioController,
                    label:      'Bio',
                    icon:       Icons.notes_outlined,
                    maxLines:   4,
                    maxLength:  300,
                    hintText:   'Ceritakan sedikit tentang dirimu...',
                  ),

                  const SizedBox(height: 6),
                  Text('Perubahan diterapkan setelah disimpan.',
                      style: TextStyle(
                        //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.3), fontSize: 11)),

                  const SizedBox(height: 20),

                  // ── Pesan sukses / error ───────────────────────
                  if (_successMsg != null) _infoBox(_successMsg!, Colors.green),
                  if (_errorMsg   != null) _infoBox(_errorMsg!,   Colors.red),

                  const SizedBox(height: 8),

                  // ── Tombol ────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _loading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            //ignore: deprecated_member_use
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Batal',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                  color: Colors.white.withOpacity(0.7))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1a56db),
                            disabledBackgroundColor: Colors.white12,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Color.fromRGBO(255, 255, 255, 1), strokeWidth: 2.5))
                              : const Text('Simpan Perubahan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      width: 90, height: 90,
      color: const Color(0xFF1a56db),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'K',
          style: const TextStyle(
              color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              //ignore: deprecated_member_use
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              //ignore: deprecated_member_use
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(title,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 10),
          //ignore: deprecated_member_use
          Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int  maxLines  = 1,
    int? maxLength,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:   controller,
      keyboardType: keyboardType,
      maxLines:     maxLines,
      maxLength:    maxLength,
      style:        const TextStyle(color: Colors.white),
      validator:    validator,
      decoration: InputDecoration(
        labelText:    label,
        hintText:     hintText,
        //ignore: deprecated_member_use
        labelStyle:   TextStyle(color: Colors.white.withOpacity(0.55)),
        //ignore: deprecated_member_use
        hintStyle:    TextStyle(color: Colors.white.withOpacity(0.25)),
        //ignore: deprecated_member_use
        prefixIcon:   Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
        filled:       true,
        //ignore: deprecated_member_use
        fillColor:    Colors.white.withOpacity(0.06),
        //ignore: deprecated_member_use
        counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1a56db), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }

  Widget _infoBox(String msg, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        //ignore: deprecated_member_use
        color:  color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        //ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.green
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: color, size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
  
  /// Compress image sebelum upload
  /// Input: original image (bisa besar)
  /// Output: compressed JPEG file (~100-200 KB)
  Future<File> _compressImage(File imageFile) async {
    try {
      // Baca image dari file
      final imageData = await imageFile.readAsBytes();
      
      // Decode image
      final originalImage = img.decodeImage(imageData);
      if (originalImage == null) {
        throw Exception('Gagal decode image');
      }
      
      // Resize ke 400x400 max, maintain aspect ratio
      final resized = img.copyResize(
        originalImage,
        width: 400,
        height: 400,
        interpolation: img.Interpolation.average,
      );
      
      // Encode ke JPEG dengan quality 75%
      final compressed = img.encodeJpg(resized, quality: 75);
      
      // Save ke temp file
      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/avatar_compressed.jpg');
      await compressedFile.writeAsBytes(compressed);
      
      // ignore: avoid_print
      print('✅ Image compressed: ${(imageData.length / 1024).toStringAsFixed(2)}KB → ${(compressed.length / 1024).toStringAsFixed(2)}KB');
      
      return compressedFile;
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Compression failed: $e, using original');
      return imageFile; // Fallback ke original kalau error
    }
  }
  
  read() {}
}