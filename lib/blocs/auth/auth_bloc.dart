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
      final user = UserModel.fromJson(response.data);
      emit(AuthAuthenticated(user));
    } catch (_) {
      await ApiService.clearToken();
      emit(AuthUnauthenticated());
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

  // ── Register ─────────────────────────────────────────────────────────────
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

      // Tidak langsung login — harus set PIN dulu
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
}