import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Register States ───────────────────────────────────────────────────────────

/// Register berhasil → simpan phone untuk diteruskan ke OTP screen
/// PERUBAHAN: tidak ada apiToken di sini — token baru ada setelah OTP verified
class RegisterSuccess extends AuthState {
  final String phone;       // Nomor HP untuk dikirim OTP
  final String phoneMasked; // Ditampilkan di UI: 0812****7890
  final String name;
  final int expiresInSeconds;
  final int cooldownSeconds;

  RegisterSuccess({
    required this.phone,
    required this.phoneMasked,
    required this.name,
    this.expiresInSeconds = 300,
    this.cooldownSeconds  = 60,
  });

  @override
  List<Object?> get props => [phone, phoneMasked, name];
}

// ── OTP States (BARU) ─────────────────────────────────────────────────────────

/// OTP berhasil dikirim / resend berhasil
class OtpSent extends AuthState {
  final String phone;
  final String phoneMasked;
  final int expiresInSeconds;
  final int cooldownSeconds;

  OtpSent({
    required this.phone,
    required this.phoneMasked,
    this.expiresInSeconds = 300,
    this.cooldownSeconds  = 60,
  });

  @override
  List<Object?> get props => [phone, phoneMasked, expiresInSeconds];
}

/// OTP salah — tampilkan sisa percobaan
class OtpError extends AuthState {
  final String message;
  final int? remainingAttempts;

  OtpError({required this.message, this.remainingAttempts});

  @override
  List<Object?> get props => [message, remainingAttempts];
}

/// OTP cooldown — user request terlalu cepat
class OtpCooldown extends AuthState {
  final int cooldownRemaining;
  OtpCooldown({required this.cooldownRemaining});
  @override
  List<Object?> get props => [cooldownRemaining];
}

/// OTP verified — lanjut ke layar Buat PIN
class OtpVerified extends AuthState {
  final String phone;
  final String name;
  final String apiToken;   // ← BARU

  OtpVerified({required this.phone, required this.name, required this.apiToken});

  @override
  List<Object?> get props => [phone, name, apiToken];
}

// ── PIN States ────────────────────────────────────────────────────────────────

/// PIN berhasil dibuat — tampilkan halaman sukses
class PinSetSuccess extends AuthState {}

// ── Password States ───────────────────────────────────────────────────────────

class ForgotPasswordSuccess extends AuthState {
  final String email;
  ForgotPasswordSuccess({required this.email});
  @override
  List<Object?> get props => [email];
}

class ResetPasswordSuccess extends AuthState {}