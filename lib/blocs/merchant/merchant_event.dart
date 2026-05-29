import 'package:equatable/equatable.dart';

abstract class MerchantEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// ── Browse ────────────────────────────────────────────────────────────────────
class LoadCategories    extends MerchantEvent {}
class LoadFeatured      extends MerchantEvent {}

class LoadMerchants extends MerchantEvent {
  final int?    categoryId;
  final String? categoryCode;
  final String? search;
  LoadMerchants({this.categoryId, this.categoryCode, this.search});
  @override
  List<Object?> get props => [categoryId, categoryCode, search];
}

class LoadProducts extends MerchantEvent {
  final int merchantId;
  LoadProducts(this.merchantId);
  @override
  List<Object?> get props => [merchantId];
}

class SearchMerchants extends MerchantEvent {
  final String keyword;
  SearchMerchants(this.keyword);
  @override
  List<Object?> get props => [keyword];
}

// ── Transaksi ─────────────────────────────────────────────────────────────────
class SubmitInquiry extends MerchantEvent {
  final int    merchantId;
  final String inputValue;
  SubmitInquiry({required this.merchantId, required this.inputValue});
  @override
  List<Object?> get props => [merchantId, inputValue];
}

class SubmitPayment extends MerchantEvent {
  final int    merchantId;
  final int    productId;
  final String inputValue;
  final String pin;
  SubmitPayment({
    required this.merchantId,
    required this.productId,
    required this.inputValue,
    required this.pin,
  });
  @override
  List<Object?> get props => [merchantId, productId, inputValue, pin];
}

class LoadMerchantTransactions extends MerchantEvent {}

class ResetMerchantState extends MerchantEvent {}