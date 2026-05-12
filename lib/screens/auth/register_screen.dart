import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {

  // ── Step 1: Form data ─────────────────────────────────────────────────────
  final _firstNameController = TextEditingController();
  final _lastNameController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  bool _obscurePassword      = true;

  // ── Step 2 & 3: Set PIN ───────────────────────────────────────────────────
  int _step = 1; // 1=form, 2=buat PIN, 3=konfirmasi PIN, 4=sukses
  String _pin        = '';
  String _pinConfirm = '';
  String _apiToken   = '';
  String _userName   = '';

  // Animasi rotasi PIN dot
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Numpad handler ────────────────────────────────────────────────────────
  void _handleNumpad(String num) {
    if (_step == 2) {
      if (num == '⌫') {
        if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
        return;
      }
      if (_pin.length >= 6) return;
      setState(() => _pin += num);
      if (_pin.length == 6) {
        // Validasi PIN
        if (RegExp(r'^(.)\1{5}$').hasMatch(_pin) || _pin == '123456' || _pin == '654321') {
          _shakeController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PIN terlalu mudah ditebak'), backgroundColor: Colors.orange),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) setState(() => _pin = '');
          });
          return;
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _step = 3);
        });
      }
    } else if (_step == 3) {
      if (num == '⌫') {
        if (_pinConfirm.isNotEmpty) setState(() => _pinConfirm = _pinConfirm.substring(0, _pinConfirm.length - 1));
        return;
      }
      if (_pinConfirm.length >= 6) return;
      setState(() => _pinConfirm += num);
      if (_pinConfirm.length == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_pinConfirm == _pin) {
            //Submit PIN ke backend
            //ignore: use_build_context_synchronously
            context.read<AuthBloc>().add(SetInitialPinSubmitted(
              pin:      _pin,
              apiToken: _apiToken,
            ));
          } else {
            _shakeController.forward(from: 0);
            //ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN tidak cocok. Coba lagi.'), backgroundColor: Colors.red),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _pinConfirm = '');
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is RegisterSuccess) {
            setState(() {
              _apiToken = state.apiToken;
              _userName = state.name;
              _step     = 2;
            });
          } else if (state is PinSetSuccess) {
            setState(() => _step = 4);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SafeArea(
          child: _step == 1
              ? _buildFormStep()
              : _step == 4
                  ? _buildSuccessStep()
                  : _buildPinStep(),
        ),
      ),
    );
  }

  // ── Step 1: Form Registrasi ───────────────────────────────────────────────
  Widget _buildFormStep() {
    return SingleChildScrollView(
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

          // Header
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
              Expanded(
                child: _buildField(
                  label: 'Nama Depan',
                  controller: _firstNameController,
                  hint: 'Nama depan',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: 'Nama Belakang',
                  controller: _lastNameController,
                  hint: 'Nama belakang',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Nomor HP',
            controller: _phoneController,
            hint: '08123456789',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Email',
            controller: _emailController,
            hint: 'email@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          // Password
          Text(
            'Password',
            style: TextStyle(
              //ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
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
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1a56db), width: 1.5),
              ),
              //ignore: deprecated_member_use
              prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.4)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.4),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state is AuthLoading ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a56db),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: state is AuthLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Daftar Sekarang',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Login Link
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  text: 'Sudah punya akun? ',
                  //ignore: deprecated_member_use
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  children: const [
                    TextSpan(
                      text: 'Masuk di sini',
                      style: TextStyle(color: Color(0xFF1a56db), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Step 2 & 3: Set PIN ───────────────────────────────────────────────────
  Widget _buildPinStep() {
    final isMakingPin   = _step == 2;
    final currentPin    = isMakingPin ? _pin : _pinConfirm;
    final title         = isMakingPin ? 'Buat PIN KyPay' : 'Konfirmasi PIN';
    final subtitle      = isMakingPin
        ? 'PIN 6 digit untuk keamanan transaksimu'
        : 'Masukkan ulang PIN yang sama';

    return Column(
      children: [
        const SizedBox(height: 40),

        // Step indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildStepDot(1, true),
              Expanded(child: Container(height: 2, color: const Color(0xFF1a56db))),
              _buildStepDot(2, true),
              Expanded(child: Container(height: 2, color: isMakingPin ? Colors.white12 : const Color(0xFF1a56db))),
              _buildStepDot(3, !isMakingPin),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            //ignore: deprecated_member_use
            color: const Color(0xFF1a56db).withOpacity(0.15),
            shape: BoxShape.circle,
            //ignore: deprecated_member_use
            border: Border.all(color: const Color(0xFF1a56db).withOpacity(0.3), width: 2),
          ),
          child: Icon(
            isMakingPin ? Icons.lock_outline : Icons.verified_outlined,
            color: const Color(0xFF1a56db),
            size: 32,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          //ignore: deprecated_member_use
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),

        const SizedBox(height: 36),

        // PIN dots
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = _shakeAnimation.value * 8 * (0.5 - (_shakeAnimation.value % 0.5));
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = currentPin.length > i;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? const Color(0xFF1a56db) : Colors.transparent,
                  border: Border.all(
                    color: filled
                        ? const Color(0xFF1a56db)
                        //ignore: deprecated_member_use
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: filled
                  //ignore: deprecated_member_use
                      ? [BoxShadow(color: const Color(0xFF1a56db).withOpacity(0.5), blurRadius: 8)]
                      : null,
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 48),

        // Numpad
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                //ignore: prefer_const_literals_to_create_immutables, avoid_types_as_parameter_names
                children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((num) {
                  final isEmpty = num == '';
                  return GestureDetector(
                    onTap: (isEmpty || isLoading) ? null : () => _handleNumpad(num),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isEmpty
                            ? Colors.transparent
                            //ignore: deprecated_member_use
                            : Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: isEmpty ? null : Border.all(
                          //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Center(
                        child: isLoading && !isEmpty && num != '⌫'
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                num,
                                style: TextStyle(
                                  color: num == '⌫'
                                  //ignore: deprecated_member_use
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.white,
                                  fontSize: num == '⌫' ? 18 : 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Back to step
        if (_step == 3)
          TextButton(
            onPressed: () => setState(() {
              _pinConfirm = '';
              _step = 2;
            }),
            child: Text(
              '← Ulangi dari awal',
              //ignore: deprecated_member_use
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
            ),
          ),
      ],
    );
  }

  // ── Step 4: Sukses ────────────────────────────────────────────────────────
  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi centang
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, val, child) => Transform.scale(
                scale: val,
                child: child,
              ),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.green.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Akun Berhasil Dibuat!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 12),

            Text(
              'Selamat datang di KyPay, $_userName!\nAkunmu sudah siap digunakan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                //ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a56db),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Masuk ke Akun',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            //ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
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
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1a56db), width: 1.5),
            ),
            //ignore: deprecated_member_use
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDot(int stepNum, bool active) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        //ignore: deprecated_member_use
        color: active ? const Color(0xFF1a56db) : Colors.white.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          '$stepNum',
          style: TextStyle(
            //ignore: deprecated_member_use
            color: active ? Colors.white : Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Submit register ───────────────────────────────────────────────────────
  void _submitRegister() {
    final firstName = _firstNameController.text.trim();
    final lastName  = _lastNameController.text.trim();
    final phone     = _phoneController.text.trim();
    final email     = _emailController.text.trim();
    final password  = _passwordController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama depan dan belakang wajib diisi'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor HP wajib diisi'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak valid'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 8 karakter'), backgroundColor: Colors.orange),
      );
      return;
    }

    context.read<AuthBloc>().add(RegisterSubmitted(
      firstName: firstName,
      lastName:  lastName,
      phone:     phone,
      email:     email,
      password:  password,
    ));
  }
}