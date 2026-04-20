abstract class PaymentEvent {}
 
class FetchProducts extends PaymentEvent {
  final String category;
  FetchProducts(this.category);
}
 
class SelectProduct extends PaymentEvent {
  final Map<String, dynamic> product;
  SelectProduct(this.product);
}
 
class SubmitPayment extends PaymentEvent {
  final String productCode;
  final String targetNumber;
  final String pin;
  SubmitPayment({
    required this.productCode,
    required this.targetNumber,
    required this.pin,
  });
}
 
class ResetPayment extends PaymentEvent {}