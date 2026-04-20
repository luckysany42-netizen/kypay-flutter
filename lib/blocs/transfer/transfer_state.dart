import 'package:equatable/equatable.dart';

abstract class TransferState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TransferInitial extends TransferState {}
class TransferSearching extends TransferState {}

class TransferReceiverFound extends TransferState {
  final String ownerName;
  final String walletNumber;
  final String? ownerAvatar;

  TransferReceiverFound({
    required this.ownerName,
    required this.walletNumber,
    this.ownerAvatar,
  });

  @override
  List<Object?> get props => [ownerName, walletNumber];
}

class TransferSearchError extends TransferState {
  final String message;
  TransferSearchError(this.message);

  @override
  List<Object?> get props => [message];
}

class TransferLoading extends TransferState {}

class TransferSuccess extends TransferState {
  final String referenceNumber;
  final double amount;
  final String receiverName;

  TransferSuccess({
    required this.referenceNumber,
    required this.amount,
    required this.receiverName,
  });

  @override
  List<Object?> get props => [referenceNumber, amount, receiverName];
}

class TransferError extends TransferState {
  final String message;
  TransferError(this.message);

  @override
  List<Object?> get props => [message];
}