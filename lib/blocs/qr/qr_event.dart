abstract class QrEvent {}

// Generate QR untuk terima pembayaran (transfer)
class GenerateQrTransfer extends QrEvent {
  final double amount;
  final String? description;
  GenerateQrTransfer({required this.amount, this.description});
}

// Generate QR untuk Bayar & Beli
// Tambahkan event ini untuk generate QR dari Bayar & Beli
class GenerateQrBill extends QrEvent {
  final String productCode;
  final String targetNumber;
  final double amount;

  GenerateQrBill({
    required this.productCode,
    required this.targetNumber,
    required this.amount,
  });

  List<Object?> get props => [productCode, targetNumber, amount];
}

// Polling status QR
class PollQrStatus extends QrEvent {
  final String token;
  PollQrStatus(this.token);
}

// Scan QR — ambil detail dulu
class ScanQrToken extends QrEvent {
  final String token;
  ScanQrToken(this.token);
}

// Bayar QR setelah konfirmasi PIN
class PayQr extends QrEvent {
  final String token;
  final String pin;
  PayQr({required this.token, required this.pin});
}

// Cancel QR
class CancelQr extends QrEvent {
  final String token;
  CancelQr(this.token);
}

class ResetQr extends QrEvent {}