abstract class TopUpEvent {}

class FetchPaymentMethods extends TopUpEvent {}

class SelectPaymentMethod extends TopUpEvent {
  final Map<String, dynamic> method;
  SelectPaymentMethod(this.method);
}

class SubmitTopUp extends TopUpEvent {
  final double amount;
  final String paymentMethod;   // nama bank, misal "BCA Transfer"
  final String paymentAccount;  // nomor rekening
  final String paymentHolder;   // nama pemilik rekening
  final String imagePath;

  SubmitTopUp({
    required this.amount,
    required this.paymentMethod,
    required this.paymentAccount,
    required this.paymentHolder,
    required this.imagePath,
  });
}

class ResetTopUp extends TopUpEvent {}

/// Dipanggil saat WalletBloc selesai fetch wallet
/// untuk cek apakah ada top up yang baru diapprove
class CheckApprovedTopUp extends TopUpEvent {}