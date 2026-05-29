import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import 'otp_screen.dart'; // BARU

/// RegisterScreen - DIPERBARUI
/// Perubahan dari versi lama:
/// - Step sekarang hanya 1 (form registrasi)
/// - Setelah register berhasil (RegisterSuccess) → navigasi ke OtpScreen
/// - OtpScreen yang handle PIN setup dan halaman sukses
/// - Hapus _step, _pin, _pinConfirm, _apiToken, _buildPinStep, _buildSuccessStep
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  bool _obscurePassword      = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            // Register berhasil → navigasi ke OTP screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: OtpScreen(
                    phone:            state.phone,
                    phoneMasked:      state.phoneMasked,
                    name:             state.name,
                    expiresInSeconds: state.expiresInSeconds,
                    cooldownSeconds:  state.cooldownSeconds,
                  ),
                ),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    //ignore: deprecated_member_use
                    child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.7), size: 20),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Buat Akun\nKyPay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftar sekarang dan mulai transaksi',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),

                const SizedBox(height: 36),

                // Nama Depan & Belakang
                Row(
                  children: [
                    Expanded(child: _buildField(
                      label: 'Nama Depan', controller: _firstNameController,
                      hint: 'Nama depan', icon: Icons.person_outline,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(
                      label: 'Nama Belakang', controller: _lastNameController,
                      hint: 'Nama belakang', icon: Icons.person_outline,
                    )),
                  ],
                ),

                const SizedBox(height: 16),

                _buildField(
                  label: 'Nomor HP', controller: _phoneController,
                  hint: '08123456789', icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 16),

                _buildField(
                  label: 'Email', controller: _emailController,
                  hint: 'email@email.com', icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                // Password
                Text('Password', style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Minimal 8 karakter',
                    //ignore: deprecated_member_use
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    //ignore: deprecated_member_use
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1a56db), width: 1.5)),
                    //ignore: deprecated_member_use
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.4)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.4)),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _submitRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a56db),
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Daftar Sekarang',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Sudah punya akun? ',
                        //ignore: deprecated_member_use
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        children: const [TextSpan(
                          text: 'Masuk di sini',
                          style: TextStyle(color: Color(0xFF1a56db), fontWeight: FontWeight.w700),
                        )],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label, required TextEditingController controller,
    required String hint, required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          //ignore: deprecated_member_use
          color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            //ignore: deprecated_member_use
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            //ignore: deprecated_member_use
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1a56db), width: 1.5)),
            //ignore: deprecated_member_use
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          ),
        ),
      ],
    );
  }

  void _submitRegister() {
    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final phone     = _phoneController.text.trim();
    final email     = _emailController.text.trim();
    final password  = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      _snack('Nama depan dan belakang wajib diisi', Colors.orange); return;
    }
    if (phone.isEmpty) {
      _snack('Nomor HP wajib diisi', Colors.orange); return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _snack('Email tidak valid', Colors.orange); return;
    }
    if (password.length < 8) {
      _snack('Password minimal 8 karakter', Colors.orange); return;
    }

    context.read<AuthBloc>().add(RegisterSubmitted(
      firstName: firstName, lastName: lastName,
      phone: phone, email: email, password: password,
    ));
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color));
  }
}