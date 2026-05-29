import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  LoginSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String password;
  RegisterSubmitted({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [firstName, lastName, phone, email, password];
}

// ── OTP Events (BARU) ─────────────────────────────────────────────────────────

class SendOtpRequested extends AuthEvent {
  final String phone;
  final String purpose;
  SendOtpRequested({required this.phone, this.purpose = 'register'});
  @override
  List<Object?> get props => [phone, purpose];
}

class VerifyOtpSubmitted extends AuthEvent {
  final String phone;
  final String code;
  final String purpose;
  VerifyOtpSubmitted({
    required this.phone,
    required this.code,
    this.purpose = 'register',
  });
  @override
  List<Object?> get props => [phone, code, purpose];
}

// ── PIN Events ────────────────────────────────────────────────────────────────

class SetInitialPinSubmitted extends AuthEvent {
  final String pin;
  final String apiToken;   // ← ganti dari phone ke apiToken
  SetInitialPinSubmitted({required this.pin, required this.apiToken});
  @override
  List<Object?> get props => [pin, apiToken];

  get phone => null;
}

// ── Auth Events ───────────────────────────────────────────────────────────────

class LogoutRequested extends AuthEvent {}
class CheckAuthStatus extends AuthEvent {}

class UpdateUserData extends AuthEvent {
  final UserModel user;
  UpdateUserData(this.user);
  @override
  List<Object?> get props => [user];
}

class ForgotPasswordSubmitted extends AuthEvent {
  final String email;
  ForgotPasswordSubmitted({required this.email});
  @override
  List<Object?> get props => [email];
}

class ResetPasswordSubmitted extends AuthEvent {
  final String token;
  final String email;
  final String password;
  final String passwordConfirmation;
  ResetPasswordSubmitted({
    required this.token,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });
  @override
  List<Object?> get props => [token, email, password, passwordConfirmation];
}