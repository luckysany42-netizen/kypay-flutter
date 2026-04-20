import 'package:equatable/equatable.dart';

abstract class TransferEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchWallet extends TransferEvent {
  final String walletNumber;
  SearchWallet(this.walletNumber);

  @override
  List<Object?> get props => [walletNumber];
}

class SubmitTransfer extends TransferEvent {
  final String receiverWalletNumber;
  final double amount;
  final String pin;
  final String? note;

  SubmitTransfer({
    required this.receiverWalletNumber,
    required this.amount,
    required this.pin,
    this.note,
  });

  @override
  List<Object?> get props => [receiverWalletNumber, amount, pin, note];
}

class ResetTransfer extends TransferEvent {}