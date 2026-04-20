import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import 'transfer_event.dart';
import 'transfer_state.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc() : super(TransferInitial()) {
    on<SearchWallet>(_onSearchWallet);
    on<SubmitTransfer>(_onSubmitTransfer);
    on<ResetTransfer>(_onReset);
  }

  Future<void> _onSearchWallet(
    SearchWallet event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferSearching());
    try {
      final response = await ApiService.dio.get(
        '/wallet/find/${event.walletNumber}',
      );
      final data = response.data['data'];
      emit(TransferReceiverFound(
        ownerName:    data['owner_name'] ?? '',
        walletNumber: data['wallet_number'] ?? '',
        ownerAvatar:  data['owner_avatar'],
      ));
    } catch (e) {
      // ✅ Baca pesan error dari Laravel response
      String message = 'Wallet tidak ditemukan';
      if (e is DioException && e.response?.data != null) {
        message = e.response?.data['message'] ?? message;
      }
      emit(TransferSearchError(message));
    }
  }

  Future<void> _onSubmitTransfer(
    SubmitTransfer event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferLoading());
    try {
      final response = await ApiService.dio.post('/transfer/', data: {
        'receiver_wallet_number': event.receiverWalletNumber,
        'amount':                 event.amount,
        'pin':                    event.pin,
        'note':                   event.note,
      });
      final data = response.data['data'];
      emit(TransferSuccess(
        referenceNumber: data['reference_number'] ?? '-',
        amount:          event.amount,
        receiverName:    data['receiver_name'] ?? '',
      ));
    } catch (e) {
      // ✅ Baca pesan error dari Laravel response
      String message = 'Transfer gagal. Coba lagi.';
      if (e is DioException && e.response?.data != null) {
        final errors = e.response?.data['errors'];
        if (errors is Map) {
          message = errors.values.first.toString();
        } else {
          message = e.response?.data['message'] ?? message;
        }
      }
      emit(TransferError(message));
    }
  }

  void _onReset(ResetTransfer event, Emitter<TransferState> emit) {
    emit(TransferInitial());
  }
}