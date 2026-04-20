import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import 'topup_event.dart';
import 'topup_state.dart';

class TopUpBloc extends Bloc<TopUpEvent, TopUpState> {
  TopUpBloc() : super(TopUpInitial()) {
    on<FetchPaymentMethods>(_onFetchMethods);
    on<SelectPaymentMethod>(_onSelectMethod);
    on<SubmitTopUp>(_onSubmit);
    on<ResetTopUp>(_onReset);
  }

  List<dynamic> _methods = [];
  Map<String, dynamic>? _selectedMethod;

  Future<void> _onFetchMethods(
    FetchPaymentMethods event,
    Emitter<TopUpState> emit,
  ) async {
    emit(TopUpMethodsLoading());
    try {
      final response = await ApiService.dio.get('/topup/payment-methods');
      // Response: { success: true, data: [...] }
      _methods = response.data['data'] ?? response.data ?? [];
      emit(TopUpMethodsLoaded(methods: _methods, selectedMethod: _selectedMethod));
    } catch (e) {
      emit(TopUpMethodsError('Gagal memuat metode pembayaran'));
    }
  }

  Future<void> _onSelectMethod(
    SelectPaymentMethod event,
    Emitter<TopUpState> emit,
  ) async {
    _selectedMethod = event.method;
    emit(TopUpMethodsLoaded(methods: _methods, selectedMethod: _selectedMethod));
  }

  Future<void> _onSubmit(
    SubmitTopUp event,
    Emitter<TopUpState> emit,
  ) async {
    emit(TopUpSubmitting(methods: _methods, selectedMethod: _selectedMethod));
    try {
      // ✅ Field names sesuai TopUpController@store di Laravel:
      // - payment_method  → nama bank/metode (string)
      // - payment_account → nomor rekening (string)
      // - payment_holder  → nama pemilik rekening (string)
      // - amount          → jumlah (numeric)
      // - proof_image     → file gambar
      final formData = FormData.fromMap({
        'amount':           event.amount.toInt(),
        'payment_method':   event.paymentMethod,   // nama bank, misal "BCA Transfer"
        'payment_account':  event.paymentAccount,  // nomor rekening
        'payment_holder':   event.paymentHolder,   // nama pemilik
        'proof_image': await MultipartFile.fromFile(
          event.imagePath,
          filename: 'bukti_transfer.jpg',
        ),
      });

      // ✅ Endpoint yang benar: /topup/ (POST)
      // Bukan /topup/request — route itu tidak ada di api.php
      final response = await ApiService.dio.post(
        '/topup/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final data = response.data['data'] ?? response.data;
      emit(TopUpSuccess(
        referenceNumber: data['reference_number'] ?? data['id']?.toString() ?? '-',
        amount:          event.amount,
        methodName:      _selectedMethod?['name'] ?? '',
      ));
    } catch (e) {
      String msg = 'Gagal mengirim pengajuan top up';
      if (e is DioException && e.response?.data != null) {
        final errors = e.response?.data['errors'];
        if (errors is Map) {
          msg = errors.values.first.toString();
        } else if (e.response?.data['message'] != null) {
          msg = e.response?.data['message'];
        }
      }
      emit(TopUpError(msg));
    }
  }

  void _onReset(ResetTopUp event, Emitter<TopUpState> emit) {
    _selectedMethod = null;
    emit(TopUpInitial());
  }
}