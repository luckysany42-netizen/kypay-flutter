abstract class QrState {}
 
class QrInitial extends QrState {}
 
class QrLoading extends QrState {}
 
// QR sudah digenerate — menunggu dibayar (polling)
class QrGenerated extends QrState {
  final String token;
  final double amount;
  final String? description;
  final String expiresAt;
  final int secondsLeft;
  final String status; // pending, paid, expired, cancelled
 
  QrGenerated({
    required this.token,
    required this.amount,
    this.description,
    required this.expiresAt,
    required this.secondsLeft,
    this.status = 'pending',
  });
 
  QrGenerated copyWith({String? status, int? secondsLeft}) => QrGenerated(
    token:       token,
    amount:      amount,
    description: description,
    expiresAt:   expiresAt,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    status:      status ?? this.status,
  );
}
 
// QR berhasil dibayar (dari sisi penerima / merchant)
class QrPaymentReceived extends QrState {
  final double amount;
  final String transactionNumber;
  QrPaymentReceived({required this.amount, required this.transactionNumber});
}
  
// Detail QR dari hasil scan
class QrScanned extends QrState {
  final String token;
  final double amount;
  final String merchantName;
  final String? merchantAvatar;
  final String? description;
  final bool isBillPayment;
  QrScanned({
    required this.token,
    required this.amount,
    required this.merchantName,
    this.merchantAvatar,
    this.description,
    this.isBillPayment = false,
  });
}
 
// Pembayaran QR berhasil (dari sisi pembayar)
class QrPaySuccess extends QrState {
  final double amount;
  final String merchantName;
  final String transactionNumber;
  final String? resultCode;
  final bool isBillPayment;
  QrPaySuccess({
    required this.amount,
    required this.merchantName,
    required this.transactionNumber,
    this.resultCode,
    this.isBillPayment = false,
  });
}
 
class QrError extends QrState {
  final String message;
  QrError(this.message);
}