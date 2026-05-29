import 'package:intl/intl.dart';

class MerchantProductModel {
  final int     id;
  final String  code;
  final String  name;
  final String? description;
  final String? validity;
  final double  sellingPrice;
  final double  adminFee;
  final double  totalPrice;
  final String? categoryTag;

  const MerchantProductModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.validity,
    required this.sellingPrice,
    required this.adminFee,
    required this.totalPrice,
    this.categoryTag,
  });

  factory MerchantProductModel.fromJson(Map<String, dynamic> json) {
    return MerchantProductModel(
      id:           json['id']            as int,
      code:         json['code']          as String,
      name:         json['name']          as String,
      description:  json['description']   as String?,
      validity:     json['validity']      as String?,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      adminFee:     (json['admin_fee']     as num).toDouble(),
      totalPrice:   (json['total_price']   as num).toDouble(),
      categoryTag:  json['category_tag']   as String?,
    );
  }

  String get formattedPrice {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(totalPrice);
  }

  String get formattedSellingPrice {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(sellingPrice);
  }
}