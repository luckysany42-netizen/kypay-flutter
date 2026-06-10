import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

/// Layar verifikasi OTP.
/// Dipanggil dari RegisterScreen setelah register berhasil (state RegisterSuccess).
///
/// Penggunaan di RegisterScreen:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => BlocProvider.value(
// ignore: unintended_html_in_doc_comment
///       value: context.read<AuthBloc>(),
///       child: OtpScreen(
///         phone:            state.phone,
///         phoneMasked:      state.phoneMasked,
///         name:             state.name,
///         expiresInSeconds: state.expiresInSeconds,
///         cooldownSeconds:  state.cooldownSeconds,
///       ),
///     ),
///   ));
class OtpScreen extends StatefulWidget {
  final String phone;
  final String phoneMasked;
  final String name;
  final int    expiresInSeconds;
  final int    cooldownSeconds;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.phoneMasked,
    required this.name,
    this.expiresInSeconds = 300,
    this.cooldownSeconds  = 60,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  final TextEditingController _otpController = TextEditingController();
  String _currentOtp = '';

  // Countdown timer OTP (5 menit)
  late int _secondsRemaining;
  Timer? _otpTimer;

  // Cooldown resend (60 detik)
  int _resendCooldown = 0;
  Timer? _resendTimer;

  // Shake animation saat kode salah
  late AnimationController _shakeController;
  late Animation<double>   _shakeAnimation;

  // Simpan sisa percobaan dari response backend
  int? _remainingAttempts;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.expiresInSeconds;
    _resendCooldown   = widget.cooldownSeconds;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _startOtpTimer();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpTimer?.cancel();
    _resendTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Timer Helpers ─────────────────────────────────────────────────────────

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  String get _formattedTimer {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _isOtpExpired    => _secondsRemaining <= 0;
  bool get _canResend       => _resendCooldown <= 0;

  // ── Actions ───────────────────────────────────────────────────────────────

  void _onOtpCompleted(String code) {
    _currentOtp = code;
    // Auto-submit saat 6 digit terisi
    _submitOtp();
  }

  void _submitOtp() {
    if (_currentOtp.length < 6) {
      _showSnackbar('Masukkan 6 digit kode OTP', Colors.orange);
      return;
    }
    if (_isOtpExpired) {
      _showSnackbar('Kode OTP sudah kedaluwarsa. Minta kode baru.', Colors.orange);
      return;
    }
    context.read<AuthBloc>().add(VerifyOtpSubmitted(
      phone:   widget.phone,
      code:    _currentOtp,
      purpose: 'register',
    ));
  }

  void _resendOtp() {
    if (!_canResend) return;

    // Reset state
    _otpController.clear();
    _currentOtp       = '';
    _remainingAttempts = null;
    _secondsRemaining = widget.expiresInSeconds;
    _resendCooldown   = widget.cooldownSeconds;

    _startOtpTimer();
    _startResendTimer();

    context.read<AuthBloc>().add(SendOtpRequested(
      phone:   widget.phone,
      purpose: 'register',
    ));
  }

  void _triggerShake() {
    _otpController.clear();
    _currentOtp = '';
    _shakeController.forward(from: 0);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpVerified) {
            // OTP verified → navigasi ke layar Buat PIN
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<AuthBloc>(),
                  child: _PinSetupScreen(
                    phone:    widget.phone,
                    name:     widget.name,
                    apiToken: state.apiToken,   // ← BARU
                  ),
                ),
              ),
            );
          } else if (state is OtpError) {
            _triggerShake();
            _remainingAttempts = state.remainingAttempts;
            _showSnackbar(state.message, Colors.red);
            setState(() {});
          } else if (state is OtpSent) {
            // Resend berhasil
            _showSnackbar('Kode OTP baru telah dikirim', Colors.green);
          } else if (state is OtpCooldown) {
            _resendCooldown = state.cooldownRemaining;
            _startResendTimer();
            _showSnackbar(
              'Tunggu ${state.cooldownRemaining} detik sebelum kirim ulang.',
              Colors.orange,
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // ── Icon ──────────────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: const Color(0xFF1a56db).withOpacity(0.15),
                    shape: BoxShape.circle,
                    //ignore: deprecated_member_use
                    border: Border.all(
                      // ignore: deprecated_member_use
                      color: const Color(0xFF1a56db).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    color: Color(0xFF1a56db),
                    size: 36,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Title ─────────────────────────────────────────────────
                const Text(
                  'Verifikasi Nomor HP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    //ignore: deprecated_member_use
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6),
                    children: [
                      const TextSpan(text: 'Kode OTP 6 digit telah dikirim via SMS ke\n'),
                      TextSpan(
                        text: widget.phoneMasked,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Countdown Timer ───────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: _isOtpExpired
                        //ignore: deprecated_member_use
                        ? Colors.red.withOpacity(0.1)
                        //ignore: deprecated_member_use
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isOtpExpired
                          //ignore: deprecated_member_use
                          ? Colors.red.withOpacity(0.3)
                          //ignore: deprecated_member_use
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isOtpExpired ? Icons.timer_off : Icons.timer_outlined,
                        size: 16,
                        color: _isOtpExpired
                            ? Colors.red
                            : const Color(0xFF1a56db),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isOtpExpired
                            ? 'Kode kedaluwarsa'
                            : 'Berlaku selama $_formattedTimer',
                        style: TextStyle(
                          color: _isOtpExpired
                              ? Colors.red
                              //ignore: deprecated_member_use
                              : Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── OTP Input (pin_code_fields) ───────────────────────────
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final offset = _shakeAnimation.value * 10 *
                        (0.5 - (_shakeAnimation.value % 0.5));
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          enabled: !isLoading && !_isOtpExpired,
                          obscureText: false,
                          animationType: AnimationType.fade,
                          keyboardType: TextInputType.number,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 54,
                            fieldWidth: 46,
                            activeFillColor: const Color(0xFF1a56db).withOpacity(0.15),//ignore: deprecated_member_use
                            inactiveFillColor: Colors.white.withOpacity(0.05),//ignore: deprecated_member_use
                            selectedFillColor: const Color(0xFF1a56db).withOpacity(0.1),//ignore: deprecated_member_use
                            activeColor: const Color(0xFF1a56db),
                            inactiveColor: Colors.white.withOpacity(0.15),//ignore: deprecated_member_use
                            selectedColor: const Color(0xFF1a56db),
                          ),
                          enableActiveFill: true,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          onChanged: (val) => setState(() => _currentOtp = val),
                          onCompleted: _onOtpCompleted,
                        );
                      },
                    ),
                  ),
                ),

                // ── Sisa percobaan warning ────────────────────────────────
                if (_remainingAttempts != null && _remainingAttempts! <= 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        //ignore: deprecated_member_use
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Sisa $_remainingAttempts percobaan',
                            style: const TextStyle(color: Colors.orange, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // ── Tombol Verifikasi ─────────────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (isLoading || _isOtpExpired || _currentOtp.length < 6)
                            ? null
                            : _submitOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a56db),
                          disabledBackgroundColor: Colors.white12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Verifikasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ── Kirim Ulang OTP ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tidak menerima kode? ',
                      //ignore: deprecated_member_use
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: _canResend ? _resendOtp : null,
                      child: Text(
                        _canResend
                            ? 'Kirim Ulang'
                            : 'Kirim Ulang (${_resendCooldown}s)',
                        style: TextStyle(
                          color: _canResend
                              ? const Color(0xFF1a56db)
                              //ignore: deprecated_member_use
                              : Colors.white.withOpacity(0.25),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Info box ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    //ignore: deprecated_member_use
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                        //ignore: deprecated_member_use
                        color: Color(0xFF1a56db), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Jangan bagikan kode OTP kepada siapapun, termasuk pihak KyPay.',
                          //ignore: deprecated_member_use
                          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PIN Setup Screen — muncul setelah OTP verified
// Dipindahkan dari RegisterScreen ke sini agar flow lebih bersih
// ═══════════════════════════════════════════════════════════════════════════════

class _PinSetupScreen extends StatefulWidget {
  final String phone;
  final String name;
  final String apiToken;
  const _PinSetupScreen({required this.phone, required this.name, required this.apiToken});

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen>
    with SingleTickerProviderStateMixin {

  int    _step       = 2; // 2=buat PIN, 3=konfirmasi PIN
  String _pin        = '';
  String _pinConfirm = '';

  late AnimationController _shakeController;
  late Animation<double>   _shakeAnimation;

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
    _shakeController.dispose();
    super.dispose();
  }

  void _handleNumpad(String num) {
    if (_step == 2) {
      if (num == '⌫') {
        if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
        return;
      }
      if (_pin.length >= 6) return;
      setState(() => _pin += num);
      if (_pin.length == 6) {
        if (RegExp(r'^(.)\1{5}$').hasMatch(_pin) || _pin == '123456' || _pin == '654321') {
          _shakeController.forward(from: 0);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('PIN terlalu mudah ditebak'),
            backgroundColor: Colors.orange,
          ));
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
            //ignore: use_build_context_synchronously
            context.read<AuthBloc>().add(SetInitialPinSubmitted(
              pin:      _pin,
              apiToken: widget.apiToken,   // ← kirim token, bukan phone
            ));
          } else {
            _shakeController.forward(from: 0);
            //ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('PIN tidak cocok. Coba lagi.'),
              backgroundColor: Colors.red,
            ));
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
          if (state is PinSetSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => _RegisterSuccessScreen(name: widget.name),
              ),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SafeArea(child: _buildPinStep()),
      ),
    );
  }

  Widget _buildPinStep() {
    final isMakingPin = _step == 2;
    final currentPin  = isMakingPin ? _pin : _pinConfirm;

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
              Expanded(child: Container(height: 2, color: const Color(0xFF1a56db))),
              _buildStepDot(3, true),
              Expanded(child: Container(height: 2, color: isMakingPin ? Colors.white12 : const Color(0xFF1a56db))),
              _buildStepDot(4, !isMakingPin),
            ],
          ),
        ),

        const SizedBox(height: 48),

        Container(
          width: 72, height: 72,
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
          isMakingPin ? 'Buat PIN KyPay' : 'Konfirmasi PIN',
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          isMakingPin ? 'PIN 6 digit untuk keamanan transaksimu' : 'Masukkan ulang PIN yang sama',
          //ignore: deprecated_member_use
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
        ),

        const SizedBox(height: 36),

        // PIN dots
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = _shakeAnimation.value * 8 * (0.5 - (_shakeAnimation.value % 0.5));
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              final filled = currentPin.length > i;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? const Color(0xFF1a56db) : Colors.transparent,
                  border: Border.all(
                    //ignore: deprecated_member_use
                    color: filled ? const Color(0xFF1a56db) : Colors.white.withOpacity(0.3),
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
                // ignore: avoid_types_as_parameter_names
                children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((num) {
                  final isEmpty = num == '';
                  return GestureDetector(
                    onTap: (isEmpty || isLoading) ? null : () => _handleNumpad(num),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isEmpty ? Colors.transparent
                            //ignore: deprecated_member_use
                            : Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        //ignore: deprecated_member_use
                        border: isEmpty ? null : Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Center(
                        child: isLoading && !isEmpty && num != '⌫'
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(num, style: TextStyle(
                                //ignore: deprecated_member_use
                                color: num == '⌫' ? Colors.white.withOpacity(0.5) : Colors.white,
                                fontSize: num == '⌫' ? 18 : 22,
                                fontWeight: FontWeight.w600,
                              )),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),

        if (_step == 3)
          TextButton(
            onPressed: () => setState(() { _pinConfirm = ''; _step = 2; }),
            child: Text('← Ulangi dari awal',
              //ignore: deprecated_member_use
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildStepDot(int stepNum, bool active) {
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        //ignore: deprecated_member_use
        color: active ? const Color(0xFF1a56db) : Colors.white.withOpacity(0.1),
      ),
      child: Center(
        child: Text('$stepNum', style: TextStyle(
          //ignore: deprecated_member_use
          color: active ? Colors.white : Colors.white.withOpacity(0.4),
          fontSize: 11, fontWeight: FontWeight.w700,
        )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Register Success Screen
// ═══════════════════════════════════════════════════════════════════════════════

class _RegisterSuccessScreen extends StatelessWidget {
  final String name;
  const _RegisterSuccessScreen({required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, val, child) =>
                      Transform.scale(scale: val, child: child),
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
                  'Selamat datang di KyPay, $name!\nAkunmu sudah siap digunakan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.6),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a56db),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Masuk ke Akun',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}