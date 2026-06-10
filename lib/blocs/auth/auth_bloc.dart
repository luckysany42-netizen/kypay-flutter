import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Simpan nama sementara untuk diteruskan dari Register → OTP → PIN → Sukses
  String _pendingName = '';

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<SendOtpRequested>(_onSendOtp);       // BARU
    on<VerifyOtpSubmitted>(_onVerifyOtp);   // BARU
    on<SetInitialPinSubmitted>(_onSetInitialPin);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordSubmitted>(_onForgotPassword);
    on<ResetPasswordSubmitted>(_onResetPassword);
    on<UpdateUserData>(_onUpdateUserData);
  }

  // ── Check Auth ────────────────────────────────────────────────────────────
  Future<void> _onCheckAuth(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      final response = await ApiService.dio.post('/verify_token', data: {
        'api_token': token,
      });
      final userData = response.data['user'] ?? response.data;
      final user = UserModel.fromJson(userData);
      if (kDebugMode) print('✅ [Auth] Token valid: ${user.name}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.contains('token') || errorStr.contains('expired')) {
        if (kDebugMode) print('🗑️  [Auth] Token expired → logout');
        await ApiService.clearToken();
        emit(AuthUnauthenticated());
      }
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> _onLogin(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await ApiService.dio.post('/login', data: {
        'phone':    event.email,
        'password': event.password,
      });
      final data  = response.data;
      final token = data['api_token'] ?? data['token'] ?? '';
      final user  = UserModel.fromJson(data);

      await ApiService.setToken(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', user.role);

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Login gagal. Periksa nomor HP dan password.'));
    }
  }

  // ── Register → otomatis kirim OTP ────────────────────────────────────────
  Future<void> _onRegister(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await ApiService.dio.post('/register', data: {
        'first_name':            event.firstName,
        'last_name':             event.lastName,
        'phone':                 event.phone,
        'email':                 event.email,
        'password':              event.password,
        'password_confirmation': event.password,
      });

      final data = response.data;

      // Simpan nama sementara untuk ditampilkan di layar sukses
      _pendingName = '${event.firstName} ${event.lastName}';

      // Backend sudah otomatis kirim OTP — ambil data dari response
      final phoneMasked       = data['data']?['phone_masked']       ?? event.phone;
      final expiresInSeconds  = data['data']?['expires_in_seconds'] ?? 300;
      final cooldownSeconds   = data['data']?['cooldown_seconds']   ?? 60;

      if (kDebugMode) print('✅ [Register] Berhasil, OTP dikirim ke $phoneMasked');

      emit(RegisterSuccess(
        phone:            event.phone,
        phoneMasked:      phoneMasked,
        name:             _pendingName,
        expiresInSeconds: expiresInSeconds,
        cooldownSeconds:  cooldownSeconds,
      ));
    } catch (e) {
      String message = 'Pendaftaran gagal. Coba lagi.';
      try {
        final response = (e as dynamic).response;
        if (response?.statusCode == 422) {
          final errors = response?.data?['errors'];
          if (errors?['email'] != null) {
            message = 'Email sudah terdaftar.';
          // ignore: curly_braces_in_flow_control_structures
          } else if (errors?['phone'] != null) message = 'Nomor HP sudah terdaftar.';
        }
      } catch (_) {}
      emit(AuthError(message));
    }
  }

  // ── Send / Resend OTP ─────────────────────────────────────────────────────
  Future<void> _onSendOtp(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await ApiService.dio.post('/otp/send', data: {
        'phone':   event.phone,
        'purpose': event.purpose,
      });

      final data = response.data['data'];

      if (kDebugMode) print('✅ [OTP] Terkirim ke ${data['phone_masked']}');

      emit(OtpSent(
        phone:            event.phone,
        phoneMasked:      data['phone_masked']       ?? event.phone,
        expiresInSeconds: data['expires_in_seconds'] ?? 300,
        cooldownSeconds:  data['cooldown_seconds']   ?? 60,
      ));
    } catch (e) {
      // Handle cooldown (HTTP 429)
      try {
        final response = (e as dynamic).response;
        if (response?.statusCode == 429) {
          final cooldown = response?.data?['data']?['cooldown_remaining'] ?? 60;
          emit(OtpCooldown(cooldownRemaining: cooldown));
          return;
        }
      } catch (_) {}
      emit(OtpError(message: 'Gagal mengirim OTP. Coba lagi.'));
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<void> _onVerifyOtp(
    VerifyOtpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await ApiService.dio.post('/otp/verify', data: {
        'phone':   event.phone,
        'code':    event.code,
        'purpose': event.purpose,
      });

      if (kDebugMode) print('✅ [OTP] Verified: ${event.phone}');

      final data      = response.data['data'];
      final apiToken  = data['api_token'] ?? '';

      // Simpan token supaya bisa dipakai set PIN
      if (apiToken.isNotEmpty) {
        await ApiService.setToken(apiToken);
      }

      // OTP verified → lanjut ke layar Buat PIN
      emit(OtpVerified(
        phone:    event.phone,
        name:     _pendingName,
        apiToken: apiToken,
      ));
    } catch (e) {
      String message = 'Kode OTP tidak valid atau sudah kedaluwarsa.';
      int? remainingAttempts;

      try {
        final response = (e as dynamic).response;
        if (response?.statusCode == 422) {
          message           = response?.data?['message'] ?? message;
          remainingAttempts = response?.data?['data']?['remaining_attempts'];
        }
      } catch (_) {}

      emit(OtpError(message: message, remainingAttempts: remainingAttempts));
    }
  }

  // ── Set Initial PIN setelah OTP verified ─────────────────────────────────
  Future<void> _onSetInitialPin(
    SetInitialPinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await ApiService.dio.post('/wallet/set-initial-pin', data: {
        'api_token':        event.apiToken,   // ← ganti dari phone ke api_token
        'pin':              event.pin,
        'pin_confirmation': event.pin,
      });

      if (kDebugMode) print('✅ [PIN] PIN berhasil dibuat untuk ${event.phone}');

      emit(PinSetSuccess());
    } catch (e) {
      emit(AuthError('Gagal membuat PIN. Coba lagi.'));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    try { await ApiService.dio.post('/logout'); } catch (_) {}
    await ApiService.clearToken();
    emit(AuthUnauthenticated());
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  Future<void> _onForgotPassword(
    ForgotPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await ApiService.dio.post('/forgot-password', data: {'email': event.email});
      emit(ForgotPasswordSuccess(email: event.email));
    } catch (e) {
      String message = 'Gagal mengirim email. Coba lagi.';
      try {
        final response = (e as dynamic).response;
        if (response?.statusCode == 404) message = 'Email tidak ditemukan.';
      } catch (_) {}
      emit(AuthError(message));
    }
  }

  // ── Reset Password ────────────────────────────────────────────────────────
  Future<void> _onResetPassword(
    ResetPasswordSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await ApiService.dio.post('/reset-password', data: {
        'token':                 event.token,
        'email':                 event.email,
        'password':              event.password,
        'password_confirmation': event.passwordConfirmation,
      });
      emit(ResetPasswordSuccess());
    } catch (e) {
      emit(AuthError('Gagal reset password. Link mungkin sudah kadaluarsa.'));
    }
  }

  // ── Update User ───────────────────────────────────────────────────────────
  Future<void> _onUpdateUserData(UpdateUserData event, Emitter<AuthState> emit) async {
    emit(AuthAuthenticated(event.user));
  }
}