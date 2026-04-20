import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _oldPassController  = TextEditingController();
  final _newPassController  = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _showOld     = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _loading     = false;
  bool _success     = false;
  String? _errorMsg;

  // Validasi kekuatan password
  bool get _hasMin8    => _newPassController.text.length >= 8;
  bool get _hasUpper   => _newPassController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber  => _newPassController.text.contains(RegExp(r'[0-9]'));

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ApiService.dio.post('/change-password', data: {
        'current_password':      _oldPassController.text,
        'password':              _newPassController.text,
        'password_confirmation': _confirmPassController.text,
      });
      setState(() { _success = true; });
    } catch (e) {
      final data = (e as dynamic).response?.data;
      final msg  = data?['errors']?['current_password'] ??
                   data?['errors']?['password'] ??
                   data?['message'] ??
                   'Gagal mengubah password.';
      setState(() => _errorMsg = msg.toString());
    } finally {
      setState(() => _loading = false);
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
        title: const Text('Ubah Password',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  // ── Tampilan sukses ─────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    //ignore: deprecated_member_use
                      color: Colors.green.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 52),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Password Berhasil Diubah!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              'Password kamu sudah diperbarui.\nSilakan gunakan password baru saat login.',
              textAlign: TextAlign.center,
              style: TextStyle(
                //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a56db),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Profil',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ubah password ───────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                //ignore: deprecated_member_use
                color: const Color(0xFF1a56db).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  //ignore: deprecated_member_use
                    color: const Color(0xFF1a56db).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF1a56db), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Gunakan password yang kuat dan mudah diingat. '
                      'Minimal 8 karakter.',
                      style: TextStyle(
                        //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Step 1: Password lama ────────────────────────────
            _stepLabel('1', 'Password Lama'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _oldPassController,
              label: 'Masukkan password lama',
              show: _showOld,
              onToggle: () => setState(() => _showOld = !_showOld),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Wajib diisi' : null,
            ),

            const SizedBox(height: 22),

            // ── Step 2: Password baru ────────────────────────────
            _stepLabel('2', 'Password Baru'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _newPassController,
              label: 'Buat password baru',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (v.length < 8) return 'Minimal 8 karakter';
                return null;
              },
            ),

            // Indikator kekuatan password
            if (_newPassController.text.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildStrengthIndicator(),
            ],

            const SizedBox(height: 22),

            // ── Step 3: Konfirmasi password ──────────────────────
            _stepLabel('3', 'Konfirmasi Password Baru'),
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _confirmPassController,
              label: 'Ulangi password baru',
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Wajib diisi';
                if (v != _newPassController.text) {
                  return 'Password tidak cocok';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Error
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMsg!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a56db),
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Ubah Password',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step label ───────────────────────────────────────────────
  Widget _stepLabel(String num, String label) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF1a56db),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
              //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }

  // ── Password field ───────────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool show,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:  controller,
      obscureText: !show,
      onChanged:   onChanged,
      style:       const TextStyle(color: Colors.white),
      validator:   validator,
      decoration: InputDecoration(
        hintText:  label,
        //ignore: deprecated_member_use
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(Icons.lock_outline,
        //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.4), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off : Icons.visibility,
            color: Colors.white38,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled:    true,
        //ignore: deprecated_member_use
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1a56db), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  // ── Password strength indicator ──────────────────────────────
  Widget _buildStrengthIndicator() {
    final checks = [
      _StrengthCheck('Minimal 8 karakter', _hasMin8),
      _StrengthCheck('Mengandung huruf kapital', _hasUpper),
      _StrengthCheck('Mengandung angka', _hasNumber),
    ];

    final passedCount = checks.where((c) => c.passed).length;
    final color = passedCount == 3
        ? Colors.green
        : passedCount == 2
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        //ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        //ignore: deprecated_member_use
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Kekuatan password: ',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text(
                passedCount == 3
                    ? 'Kuat'
                    : passedCount == 2
                        ? 'Sedang'
                        : 'Lemah',
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < passedCount
                        ? color
                        //ignore: deprecated_member_use
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          ...checks.map((c) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Row(
                  children: [
                    Icon(
                      c.passed
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      color: c.passed ? Colors.green : Colors.white24,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(c.label,
                        style: TextStyle(
                            color: c.passed
                            //ignore: deprecated_member_use
                                ? Colors.white.withOpacity(0.7)
                                //ignore: deprecated_member_use
                                : Colors.white.withOpacity(0.3),
                            fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _StrengthCheck {
  final String label;
  final bool passed;
  const _StrengthCheck(this.label, this.passed);
}