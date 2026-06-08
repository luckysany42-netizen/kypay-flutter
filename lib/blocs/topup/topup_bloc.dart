import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'topup_event.dart';
import 'topup_state.dart';

class TopUpBloc extends Bloc<TopUpEvent, TopUpState> {
  TopUpBloc() : super(TopUpInitial()) {
    on<FetchPaymentMethods>(_onFetchMethods);
    on<SelectPaymentMethod>(_onSelectMethod);
    on<SubmitTopUp>(_onSubmit);
    on<ResetTopUp>(_onReset);
    on<CheckApprovedTopUp>(_onCheckApproved); // BARU
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
      final formData = FormData.fromMap({
        'amount':          event.amount.toInt(),
        'payment_method':  event.paymentMethod,
        'payment_account': event.paymentAccount,
        'payment_holder':  event.paymentHolder,
        'proof_image': await MultipartFile.fromFile(
          event.imagePath,
          filename: 'bukti_transfer.jpg',
        ),
      });

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

  // ── Cek top up yang baru diapprove ──────────────────────────────────────
  // Dipanggil oleh WalletBloc setelah fetch wallet berhasil.
  // Membandingkan ID top up approved terbaru dengan yang terakhir dilihat user
  // (disimpan di SharedPreferences) untuk mendeteksi approval baru.
  Future<void> _onCheckApproved(
    CheckApprovedTopUp event,
    Emitter<TopUpState> emit,
  ) async {
    try {
      final prefs        = await SharedPreferences.getInstance();
      final lastSeenApprovedId   = prefs.getInt('last_seen_approved_topup_id') ?? 0;

      // Fetch riwayat top up user
      final response     = await ApiService.dio.get('/topup/');
      final list         = response.data['data'] as List? ?? [];

      // ── Cek top up dengan status 'approved' yang belum pernah dilihat ──
      final newlyApproved = list.where((trx) {
        final status = trx['status']?.toString().toLowerCase() ?? '';
        final id     = int.tryParse(trx['id'].toString()) ?? 0;
        return status == 'approved' && id > lastSeenApprovedId;
      }).toList();

      if (newlyApproved.isNotEmpty) {
        // Ambil yang terbaru
        final latest = newlyApproved.reduce((a, b) {
          final aId = int.tryParse(a['id'].toString()) ?? 0;
          final bId = int.tryParse(b['id'].toString()) ?? 0;
          return aId > bId ? a : b;
        });

        // Simpan ID terbaru supaya tidak muncul lagi di refresh berikutnya
        final latestId = int.tryParse(latest['id'].toString()) ?? 0;
        await prefs.setInt('last_seen_approved_topup_id', latestId);

        emit(TopUpApproved(
          amount:          (latest['amount'] as num?)?.toDouble() ?? 0,
          methodName:      latest['payment_method']?.toString() ?? 'Transfer',
          referenceNumber: latest['reference_number']?.toString()
              ?? latest['id']?.toString()
              ?? '-',
          approvedAt:      latest['updated_at']?.toString()
              ?? DateTime.now().toIso8601String(),
        ));
        return; // Hanya emit satu event, jangan lanjut ke rejected check
      }

      // ── Cek top up dengan status 'rejected' yang belum pernah dilihat ──
      final lastSeenRejectedId = prefs.getInt('last_seen_rejected_topup_id') ?? 0;

      final newlyRejected = list.where((trx) {
        final status = trx['status']?.toString().toLowerCase() ?? '';
        final id     = int.tryParse(trx['id'].toString()) ?? 0;
        return status == 'rejected' && id > lastSeenRejectedId;
      }).toList();

      if (newlyRejected.isNotEmpty) {
        final latest = newlyRejected.reduce((a, b) {
          final aId = int.tryParse(a['id'].toString()) ?? 0;
          final bId = int.tryParse(b['id'].toString()) ?? 0;
          return aId > bId ? a : b;
        });

        final latestRejectedId = int.tryParse(latest['id'].toString()) ?? 0;
        await prefs.setInt('last_seen_rejected_topup_id', latestRejectedId);

        emit(TopUpRejected(
          amount:          (latest['amount'] as num?)?.toDouble() ?? 0,
          methodName:      latest['payment_method']?.toString() ?? 'Transfer',
          referenceNumber: latest['reference_number']?.toString()
              ?? latest['id']?.toString()
              ?? '-',
          adminNote:       latest['admin_note']?.toString() ?? 'Tidak ada keterangan.',
          rejectedAt:      latest['reviewed_at']?.toString()
              ?? DateTime.now().toIso8601String(),
        ));
      }
    } catch (_) {
      // Silent fail — jangan ganggu UX jika cek gagal
    }
  }
}