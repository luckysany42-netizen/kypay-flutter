import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:kypay/blocs/qr/qr_event.dart';
import 'package:kypay/blocs/qr/qr_state.dart';
import '../../services/api_service.dart';

class QrBloc extends Bloc<QrEvent, QrState> {
  QrBloc() : super(QrInitial()) {
    on<GenerateQrTransfer>(_onGenerateTransfer);
    on<GenerateQrBill>(_onGenerateQrBill);
    on<PollQrStatus>(_onPollStatus);
    on<ScanQrToken>(_onScanQr);
    on<PayQr>(_onPayQr);
    on<CancelQr>(_onCancelQr);
    on<ResetQr>(_onReset);
  }

  Timer? _pollTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 300;

  void _stopTimers() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pollTimer = null;
    _countdownTimer = null;
  }

  // ── Generate QR Transfer ────────────────────────────────────────────────
  Future<void> _onGenerateTransfer(
    GenerateQrTransfer event,
    Emitter<QrState> emit,
  ) async {
    _stopTimers();
    emit(QrLoading());
    try {
      final response = await ApiService.dio.post(
        '/qr-payment/generate',
        data: {
          'amount': event.amount.toInt(),
          'description': event.description ?? 'Transfer KyPay',
        },
      );
      final data = response.data['data'];
      _secondsLeft = data['expires_in'] ?? 300;

      final generated = QrGenerated(
        token: data['qr_token'],
        amount: (data['amount'] as num).toDouble(),
        description: data['description'],
        expiresAt: data['expires_at'].toString(),
        secondsLeft: _secondsLeft,
      );
      emit(generated);
      _startPollingAndCountdown(data['qr_token'], generated, emit);
    } catch (e) {
      String msg = 'Gagal membuat QR';
      if (e is DioException) msg = e.response?.data['message'] ?? msg;
      emit(QrError(msg));
    }
  }

  // ── Generate QR Bill ────────────────────────────────────────────────────
  Future<void> _onGenerateQrBill(
    GenerateQrBill event,
    Emitter<QrState> emit,
  ) async {
    _stopTimers();
    emit(QrLoading());
    try {
      final response = await ApiService.dio.post(
        '/qr-payment/generate',
        data: {
          'amount': event.amount.toInt(),
          'type': 'bill_payment',
          'product_code': event.productCode,
          'target_number': event.targetNumber,
        },
      );
      final data = response.data['data'];
      final token = data['token'] ?? data['qr_token'];
      if (token == null || token.toString().isEmpty) {
        throw Exception('Token QR tidak ditemukan');
      }

      final amount = (data['amount'] as num?)?.toDouble() ?? event.amount;
      final expiresAt = data['expires_at']?.toString() ?? '';
      final seconds = (data['expires_in'] as int?) ?? 300;

      emit(
        QrGenerated(
          token: token.toString(),
          amount: amount,
          secondsLeft: seconds,
          description: data['description']?.toString() ?? 'Bayar & Beli',
          expiresAt: expiresAt,
        ),
      );
      _startPolling(token.toString(), emit);
    } catch (e) {
      String msg = 'Gagal membuat QR pembayaran';
      if (e is DioException) {
        msg = e.response?.data['message'] ?? msg;
      } else if (e is Exception) {
        msg = e.toString();
      }
      emit(QrError(msg));
    }
  }

  // ── Polling + Countdown ─────────────────────────────────────────────────
  void _startPollingAndCountdown(
    String token,
    QrGenerated initial,
    Emitter<QrState> emit,
  ) {
    // Countdown setiap detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _stopTimers();
        if (!isClosed) add(PollQrStatus(token)); // cek status final
      }
    });

    // Polling setiap 2 detik
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isClosed) add(PollQrStatus(token));
    });
  }

  void _startPolling(String token, Emitter<QrState> emit) {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isClosed) add(PollQrStatus(token));
    });
  }

  Future<void> _onPollStatus(PollQrStatus event, Emitter<QrState> emit) async {
    try {
      final response = await ApiService.dio.get(
        '/qr-payment/status/${event.token}',
      );
      final data = response.data['data'];
      final status = data['status'] as String;

      if (status == 'paid') {
        _stopTimers();
        emit(
          QrPaymentReceived(
            amount: (data['amount'] as num).toDouble(),
            transactionNumber: event.token,
          ),
        );
      } else if (status == 'expired' || status == 'cancelled') {
        _stopTimers();
        emit(QrError('QR sudah $status'));
      } else if (state is QrGenerated) {
        // Update countdown di state
        emit(
          (state as QrGenerated).copyWith(
            status: status,
            secondsLeft: _secondsLeft,
          ),
        );
      }
    } catch (_) {}
  }

  // ── Scan QR ─────────────────────────────────────────────────────────────
  Future<void> _onScanQr(ScanQrToken event, Emitter<QrState> emit) async {
    emit(QrLoading());
    try {
      final response = await ApiService.dio.get(
        '/qr-payment/detail/${event.token}',
      );
      final data = response.data['data'];
      emit(
        QrScanned(
          token: data['qr_token'],
          amount: (data['amount'] as num).toDouble(),
          merchantName: data['merchant_name'] ?? '',
          merchantAvatar: data['merchant_avatar'],
          description: data['description'],
          isBillPayment: data['is_bill_payment'] ?? false,
        ),
      );
    } catch (e) {
      String msg = 'QR tidak valid atau sudah expired';
      if (e is DioException) msg = e.response?.data['message'] ?? msg;
      emit(QrError(msg));
    }
  }

  // ── Bayar QR ─────────────────────────────────────────────────────────────
  Future<void> _onPayQr(PayQr event, Emitter<QrState> emit) async {
    emit(QrLoading());
    try {
      final response = await ApiService.dio.post(
        '/qr-payment/pay',
        data: {'qr_token': event.token, 'pin': event.pin},
      );
      final data = response.data['data'];
      emit(
        QrPaySuccess(
          amount: (data['amount'] as num).toDouble(),
          merchantName: data['merchant_name'] ?? '',
          transactionNumber: data['transaction_number'] ?? '-',
          resultCode: data['bill']?['result_code'],
          isBillPayment: data['is_bill_payment'] ?? false,
        ),
      );
    } catch (e) {
      String msg = 'Pembayaran gagal';
      if (e is DioException) msg = e.response?.data['message'] ?? msg;
      emit(QrError(msg));
    }
  }

  // ── Cancel QR ────────────────────────────────────────────────────────────
  Future<void> _onCancelQr(CancelQr event, Emitter<QrState> emit) async {
    _stopTimers();
    try {
      await ApiService.dio.delete('/qr-payment/${event.token}/cancel');
    } catch (_) {}
    emit(QrInitial());
  }

  void _onReset(ResetQr event, Emitter<QrState> emit) {
    _stopTimers();
    emit(QrInitial());
  }

  @override
  Future<void> close() {
    _stopTimers();
    return super.close();
  }
}
