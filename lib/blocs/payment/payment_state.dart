abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentProductsLoading extends PaymentState {}

class PaymentProductsLoaded extends PaymentState {
  final List<dynamic> products;
  final Map<String, dynamic>? selectedProduct;
  PaymentProductsLoaded({required this.products, this.selectedProduct});
}

class PaymentProductsError extends PaymentState {
  final String message;
  PaymentProductsError(this.message);
}

class PaymentSubmitting extends PaymentProductsLoaded {
  PaymentSubmitting({
    required super.products,
    super.selectedProduct,
  });
}

class PaymentSuccess extends PaymentState {
  final String transactionNumber;
  final String productName;
  final String provider;
  final String targetNumber;
  final String category;
  final String? resultCode;
  final double amount;

  PaymentSuccess({
    required this.transactionNumber,
    required this.productName,
    required this.provider,
    required this.targetNumber,
    required this.category,
    this.resultCode,
    required this.amount,
  });
}

class PaymentError extends PaymentState {
  final String message;
  PaymentError(this.message);
}
