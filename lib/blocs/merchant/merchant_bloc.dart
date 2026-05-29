import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../services/api_service.dart';
import 'merchant_event.dart';
import 'merchant_state.dart';
import '../../models/merchant_category_model.dart';
import '../../models/merchant_model.dart';
import '../../models/merchant_product_model.dart';

class MerchantBloc extends Bloc<MerchantEvent, MerchantState> {
  // Simpan sementara untuk diteruskan antar screen
  MerchantModel?        _selectedMerchant;
  MerchantProductModel? _selectedProduct;

  MerchantModel?        get selectedMerchant => _selectedMerchant;
  MerchantProductModel? get selectedProduct  => _selectedProduct;

  void selectMerchant(MerchantModel m) => _selectedMerchant = m;
  void selectProduct(MerchantProductModel p) => _selectedProduct = p;

  MerchantBloc() : super(MerchantInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<LoadFeatured>(_onLoadFeatured);
    on<LoadMerchants>(_onLoadMerchants);
    on<LoadProducts>(_onLoadProducts);
    on<SearchMerchants>(_onSearchMerchants);
    on<SubmitInquiry>(_onSubmitInquiry);
    on<SubmitPayment>(_onSubmitPayment);
    on<LoadMerchantTransactions>(_onLoadMerchantTransactions);
    on<ResetMerchantState>((_, emit) => emit(MerchantInitial()));
  }

  // ── Load Categories ───────────────────────────────────────────────────────
  Future<void> _onLoadCategories(LoadCategories event, Emitter<MerchantState> emit) async {
    emit(MerchantLoading());
    try {
      final response = await ApiService.dio.get('/merchant/categories');
      final list = (response.data['data'] as List)
          .map((e) => MerchantCategoryModel.fromJson(e))
          .toList();
      emit(CategoriesLoaded(list));
    } catch (e) {
      if (kDebugMode) print('❌ [Merchant] LoadCategories: $e');
      emit(MerchantError('Gagal memuat kategori.'));
    }
  }

  // ── Load Featured ─────────────────────────────────────────────────────────
  Future<void> _onLoadFeatured(LoadFeatured event, Emitter<MerchantState> emit) async {
    emit(MerchantLoading());
    try {
      final response = await ApiService.dio.get('/merchant/featured');
      final list = (response.data['data'] as List)
          .map((e) => MerchantModel.fromJson(e))
          .toList();
      emit(FeaturedLoaded(list));
    } catch (e) {
      if (kDebugMode) print('❌ [Merchant] LoadFeatured: $e');
      emit(MerchantError('Gagal memuat merchant unggulan.'));
    }
  }

  // ── Load Merchants ────────────────────────────────────────────────────────
  Future<void> _onLoadMerchants(LoadMerchants event, Emitter<MerchantState> emit) async {
    emit(MerchantLoading());
    try {
      final params = <String, dynamic>{};
      if (event.categoryId   != null) params['category_id']   = event.categoryId;
      if (event.categoryCode != null) params['category_code'] = event.categoryCode;
      if (event.search       != null) params['search']        = event.search;

      final response = await ApiService.dio.get('/merchant', queryParameters: params);
      final list = (response.data['data'] as List)
          .map((e) => MerchantModel.fromJson(e))
          .toList();
      emit(MerchantsLoaded(list, categoryCode: event.categoryCode));
    } catch (e) {
      if (kDebugMode) print('❌ [Merchant] LoadMerchants: $e');
      emit(MerchantError('Gagal memuat daftar merchant.'));
    }
  }

  // ── Search Merchants ──────────────────────────────────────────────────────
  Future<void> _onSearchMerchants(SearchMerchants event, Emitter<MerchantState> emit) async {
    emit(MerchantLoading());
    try {
      final response = await ApiService.dio.get('/merchant', queryParameters: {
        'search': event.keyword,
      });
      final list = (response.data['data'] as List)
          .map((e) => MerchantModel.fromJson(e))
          .toList();
      emit(MerchantsLoaded(list));
    } catch (e) {
      emit(MerchantError('Gagal mencari merchant.'));
    }
  }

  // ── Load Products ─────────────────────────────────────────────────────────
  Future<void> _onLoadProducts(LoadProducts event, Emitter<MerchantState> emit) async {
    emit(MerchantLoading());
    try {
      final response = await ApiService.dio.get('/merchant/${event.merchantId}/products');
      final list = (response.data['data'] as List)
          .map((e) => MerchantProductModel.fromJson(e))
          .toList();
      emit(ProductsLoaded(
        products: list,
        merchant: _selectedMerchant!,
      ));
    } catch (e) {
      if (kDebugMode) print('❌ [Merchant] LoadProducts: $e');
      emit(MerchantError('Gagal memuat produk.'));
    }
  }

  // ── Submit Inquiry ────────────────────────────────────────────────────────
  Future<void> _onSubmitInquiry(SubmitInquiry event, Emitter<MerchantState> emit) async {
    emit(MerchantLoading());
    try {
      final response = await ApiService.dio.post('/merchant/inquiry', data: {
        'merchant_id': event.merchantId,
        'input_value': event.inputValue,
      });
      emit(InquiryLoaded(
        inquiryData: response.data['data'] as Map<String, dynamic>,
        merchant:    _selectedMerchant!,
        product:     _selectedProduct!,
      ));
    } catch (e) {
      String message = 'Gagal cek tagihan. Periksa nomor pelanggan.';
      try {
        message = (e as dynamic).response?.data?['message'] ?? message;
      } catch (_) {}
      emit(MerchantError(message));
    }
  }

  // ── Submit Payment ────────────────────────────────────────────────────────
  Future<void> _onSubmitPayment(SubmitPayment event, Emitter<MerchantState> emit) async {
    emit(MerchantLoading());
    try {
      final idempotencyKey = const Uuid().v4();

      final response = await ApiService.dio.post('/merchant/payment', data: {
        'merchant_id':     event.merchantId,
        'product_id':      event.productId,
        'input_value':     event.inputValue,
        'pin':             event.pin,
        'idempotency_key': idempotencyKey,
      });

      emit(PaymentSuccess(response.data['data'] as Map<String, dynamic>));
    } catch (e) {
      String message = 'Pembayaran gagal. Coba lagi.';
      try {
        message = (e as dynamic).response?.data?['message'] ?? message;
      } catch (_) {}
      emit(MerchantError(message));
    }
  }

  // ── Load Merchant Transactions ────────────────────────────────────────────
  Future<void> _onLoadMerchantTransactions(
    LoadMerchantTransactions event,
    Emitter<MerchantState> emit,
  ) async {
    emit(MerchantLoading());
    try {
      final response = await ApiService.dio.get('/merchant/transactions/history');
      final list = response.data['data'] as List? ?? [];
      emit(MerchantTransactionsLoaded(list));
    } catch (e) {
      if (kDebugMode) print('❌ [Merchant] LoadTransactions: $e');
      emit(MerchantError('Gagal memuat riwayat layanan digital.'));
    }
  }
}