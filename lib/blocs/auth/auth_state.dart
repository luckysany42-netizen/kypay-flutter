import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ✅ Register berhasil — simpan token untuk set PIN
class RegisterSuccess extends AuthState {
  final String apiToken;
  final String name;
  RegisterSuccess({required this.apiToken, required this.name});

  @override
  List<Object?> get props => [apiToken, name];
}

// ✅ PIN berhasil dibuat — siap login
class PinSetSuccess extends AuthState {}