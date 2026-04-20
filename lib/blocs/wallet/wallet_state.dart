import 'package:equatable/equatable.dart';
import '../../models/wallet_model.dart';

abstract class WalletState extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}
class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final WalletModel wallet;
  final List<dynamic> transactions;

  WalletLoaded({required this.wallet, this.transactions = const []});

  @override
  List<Object?> get props => [wallet, transactions];
}

class WalletError extends WalletState {
  final String message;
  WalletError(this.message);

  @override
  List<Object?> get props => [message];
}