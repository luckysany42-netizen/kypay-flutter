import 'package:equatable/equatable.dart';

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

class SetInitialPinSubmitted extends AuthEvent {
  final String pin;
  final String apiToken;

  SetInitialPinSubmitted({required this.pin, required this.apiToken});

  @override
  List<Object?> get props => [pin, apiToken];
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

// ✅ Kirim email lupa password
class ForgotPasswordSubmitted extends AuthEvent {
  final String email;
  ForgotPasswordSubmitted({required this.email});

  @override
  List<Object?> get props => [email];
}

// ✅ Reset password dengan token dari email
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