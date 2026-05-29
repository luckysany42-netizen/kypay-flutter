import 'package:equatable/equatable.dart';
import '../../models/merchant_category_model.dart';
import '../../models/merchant_model.dart';
import '../../models/merchant_product_model.dart';

abstract class MerchantState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MerchantInitial extends MerchantState {}
class MerchantLoading extends MerchantState {}

// ── Browse States ─────────────────────────────────────────────────────────────

class CategoriesLoaded extends MerchantState {
  final List<MerchantCategoryModel> categories;
  CategoriesLoaded(this.categories);
  @override
  List<Object?> get props => [categories];
}

class FeaturedLoaded extends MerchantState {
  final List<MerchantModel> merchants;
  FeaturedLoaded(this.merchants);
  @override
  List<Object?> get props => [merchants];
}

class MerchantsLoaded extends MerchantState {
  final List<MerchantModel> merchants;
  final String?             categoryCode;
  MerchantsLoaded(this.merchants, {this.categoryCode});
  @override
  List<Object?> get props => [merchants, categoryCode];
}

class ProductsLoaded extends MerchantState {
  final List<MerchantProductModel> products;
  final MerchantModel              merchant;
  ProductsLoaded({required this.products, required this.merchant});
  @override
  List<Object?> get props => [products, merchant];
}

// ── Transaksi States ──────────────────────────────────────────────────────────

class InquiryLoaded extends MerchantState {
  final Map<String, dynamic> inquiryData;
  final MerchantModel        merchant;
  final MerchantProductModel product;
  InquiryLoaded({
    required this.inquiryData,
    required this.merchant,
    required this.product,
  });
  @override
  List<Object?> get props => [inquiryData, merchant, product];
}

class PaymentSuccess extends MerchantState {
  final Map<String, dynamic> receiptData;
  PaymentSuccess(this.receiptData);
  @override
  List<Object?> get props => [receiptData];
}

class MerchantTransactionsLoaded extends MerchantState {
  final List<dynamic> transactions;
  MerchantTransactionsLoaded(this.transactions);
  @override
  List<Object?> get props => [transactions];
}

class MerchantError extends MerchantState {
  final String message;
  MerchantError(this.message);
  @override
  List<Object?> get props => [message];
}