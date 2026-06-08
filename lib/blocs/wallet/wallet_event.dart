import '../topup/topup_bloc.dart';

abstract class WalletEvent {}

/// Fetch wallet + transaksi.
/// [topUpBloc] opsional — jika disediakan, setelah fetch selesai akan
/// trigger CheckApprovedTopUp untuk deteksi top up yang baru diapprove.
class FetchWallet extends WalletEvent {
  final TopUpBloc? topUpBloc;
  FetchWallet({this.topUpBloc});
}

class FetchTransactions extends WalletEvent {}