import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<SetInitialPinSubmitted>(_onSetInitialPin);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordSubmitted>(_onForgotPassword);
    on<ResetPasswordSubmitted>(_onResetPassword);
    on<UpdateUserData>(_onUpdateUserData);
  }

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
      debugPrint('✅ [Verify Token] Response: ${response.data}');
      final user = UserModel.fromJson(response.data);
      if (kDebugMode) {
        print('✅ [Verify Token] User loaded: ${user.name} (token: ${user.apiToken.substring(0, 10)}...)');
      }
      emit(AuthAuthenticated(user));
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Verify Token] Error: $e');
      }
      final errorStr = e.toString();
      
      // Hanya logout jika error 401 (Unauthorized) atau token invalid
      if (errorStr.contains('401') || errorStr.contains('token') || errorStr.contains('expired')) {
        if (kDebugMode) {
          print('🗑️  [Verify Token] Token invalid/expired → LOGOUT');
        }
        await ApiService.clearToken();
        emit(AuthUnauthenticated());
      } else {
        // Jangan logout untuk error lain (network, dll) — keep current state
        if (kDebugMode) {
          print('⚠️  [Verify Token] Network/parse error → Keep current state');
        }
        // Jika ada state sebelumnya, tetap gunakan itu
      }
    }
  }

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

  // ── Register ──────────────────────────────────────────────────────────────
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

      final data  = response.data;
      final token = data['api_token'] ?? data['token'] ?? '';
      final name  = '${event.firstName} ${event.lastName}';

      emit(RegisterSuccess(apiToken: token, name: name));
    } catch (e) {
      String message = 'Pendaftaran gagal. Coba lagi.';
      if (e.toString().contains('422') || e.toString().contains('email')) {
        message = 'Email sudah terdaftar. Gunakan email lain.';
      }
      emit(AuthError(message));
    }
  }

  // ── Set Initial PIN setelah register ─────────────────────────────────────
  Future<void> _onSetInitialPin(
    SetInitialPinSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await ApiService.dio.post('/wallet/set-initial-pin', data: {
        'api_token':        event.apiToken,
        'pin':              event.pin,
        'pin_confirmation': event.pin,
      });
      emit(PinSetSuccess());
    } catch (e) {
      emit(AuthError('Gagal membuat PIN. Coba lagi.'));
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await ApiService.dio.post('/logout');
    } catch (_) {}
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
      await ApiService.dio.post('/forgot-password', data: {
        'email': event.email,
      });
      emit(ForgotPasswordSuccess(email: event.email));
    } catch (e) {
      String message = 'Gagal mengirim email. Coba lagi.';
      try {
        final response = (e as dynamic).response;
        if (response?.statusCode == 404) {
          message = 'Email tidak ditemukan di sistem kami.';
        } else if (response?.data?['errors']?['email'] != null) {
          message = response.data['errors']['email'];
        }
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
      String message = 'Gagal reset password. Link mungkin sudah kadaluarsa.';
      try {
        final response = (e as dynamic).response;
        if (response?.data?['errors']?['token'] != null) {
          message = response.data['errors']['token'];
        }
      } catch (_) {}
      emit(AuthError(message));
    }
  }

  // ── Update User Data (dari response upload avatar, dll) ────────────────────
  Future<void> _onUpdateUserData(
    UpdateUserData event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthAuthenticated(event.user));
  }
}