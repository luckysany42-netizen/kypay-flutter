import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc() : super(PaymentInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<SelectProduct>(_onSelectProduct);
    on<SubmitPayment>(_onSubmitPayment);
    on<ResetPayment>(_onReset);
  }

  List<dynamic> _products = [];
  Map<String, dynamic>? _selectedProduct;

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentProductsLoading());
    try {
      final response = await ApiService.dio.get(
        '/payment/products',
        queryParameters: {'category': event.category},
      );
      _products = response.data['data'] ?? [];
      _selectedProduct = null;
      emit(PaymentProductsLoaded(products: _products, selectedProduct: null));
    } catch (e) {
      emit(PaymentProductsError('Gagal memuat produk'));
    }
  }

  void _onSelectProduct(SelectProduct event, Emitter<PaymentState> emit) {
    _selectedProduct = event.product;
    emit(
      PaymentProductsLoaded(
        products: _products,
        selectedProduct: _selectedProduct,
      ),
    );
  }

  Future<void> _onSubmitPayment(
    SubmitPayment event,
    Emitter<PaymentState> emit,
  ) async {
    emit(
      PaymentSubmitting(products: _products, selectedProduct: _selectedProduct),
    );
    try {
      final response = await ApiService.dio.post(
        '/payment/',
        data: {
          'product_code': event.productCode,
          'target_number': event.targetNumber,
          'pin': event.pin,
        },
      );
      final data = response.data['data'];
      emit(
        PaymentSuccess(
          transactionNumber: data['transaction_number'] ?? '-',
          productName: data['product_name'] ?? '',
          provider: data['provider'] ?? '',
          targetNumber: data['target_number'] ?? '',
          category: data['category'] ?? '',
          resultCode: data['result_code'],
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
        ),
      );
    } catch (e) {
      String msg = 'Pembayaran gagal. Coba lagi.';
      if (e is DioException && e.response?.data != null) {
        msg = e.response?.data['message'] ?? msg;
      }
      emit(PaymentError(msg));
    }
  }

  void _onReset(ResetPayment event, Emitter<PaymentState> emit) {
    _products = [];
    _selectedProduct = null;
    emit(PaymentInitial());
  }
}
