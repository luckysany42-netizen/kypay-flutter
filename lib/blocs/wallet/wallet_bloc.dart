import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import '../../models/wallet_model.dart';
import '../topup/topup_event.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc() : super(WalletInitial()) {
    on<FetchWallet>(_onFetchWallet);
    on<FetchTransactions>(_onFetchTransactions);
  }

  WalletModel? _wallet;
  List<dynamic> _transactions = [];

  Future<void> _onFetchWallet(
    FetchWallet event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());
    try {
      final walletRes = await ApiService.dio.get('/wallet');
      final trxRes    = await ApiService.dio.get('/wallet/all-transactions');

      final data  = walletRes.data['data']
                ?? walletRes.data['wallet']
                ?? walletRes.data;
      _wallet       = WalletModel.fromJson(data);
      _transactions = trxRes.data['data'] ?? [];

      emit(WalletLoaded(wallet: _wallet!, transactions: _transactions));

      // Setelah wallet berhasil dimuat, cek apakah ada top up yang baru diapprove.
      // TopUpBloc harus tersedia di widget tree (sudah ada di main.dart).
      // Gunakan event.topUpBloc jika tersedia, atau skip jika tidak.
      if (event.topUpBloc != null) {
        event.topUpBloc!.add(CheckApprovedTopUp());
      }
    } catch (e) {
      emit(WalletError('Gagal memuat wallet: $e'));
    }
  }

  Future<void> _onFetchTransactions(
    FetchTransactions event,
    Emitter<WalletState> emit,
  ) async {
    if (_wallet == null) return;
    try {
      final response = await ApiService.dio.get('/wallet/all-transactions');
      _transactions  = response.data['data'] ?? [];
      emit(WalletLoaded(wallet: _wallet!, transactions: _transactions));
    } catch (e) {
      emit(WalletError('Gagal memuat transaksi'));
    }
  }
}