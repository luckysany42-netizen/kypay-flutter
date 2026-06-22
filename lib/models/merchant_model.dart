class MerchantModel {
  final int    id;
  final String code;
  final String name;
  final String? logoUrl;
  final bool   hasInquiry;
  final bool   isFeatured;
  final MerchantInputConfig inputConfig;
  final MerchantCategoryInfo? category;

  const MerchantModel({
    required this.id,
    required this.code,
    required this.name,
    this.logoUrl,
    required this.hasInquiry,
    required this.isFeatured,
    required this.inputConfig,
    this.category,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      id:          json['id'] as int,
      code:        json['code'] as String,
      name:        json['name'] as String,
      logoUrl:     json['logo_url'] as String?,
      hasInquiry:  json['has_inquiry'] as bool? ?? false,
      isFeatured:  json['is_featured'] as bool? ?? false,
      inputConfig: MerchantInputConfig.fromJson(
        json['input_config'] as Map<String, dynamic>? ?? {},
      ),
      category: json['category'] != null
          ? MerchantCategoryInfo.fromJson(json['category'])
          : null,
    );
  }

  get logo => null;
}

class MerchantInputConfig {
  final String  type;
  final String  label;
  final String  hint;
  final String? prefix;
  final int     minLength;
  final int     maxLength;

  const MerchantInputConfig({
    required this.type,
    required this.label,
    required this.hint,
    this.prefix,
    required this.minLength,
    required this.maxLength,
  });

  factory MerchantInputConfig.fromJson(Map<String, dynamic> json) {
    return MerchantInputConfig(
      type:      json['type']       as String? ?? 'phone_number',
      label:     json['label']      as String? ?? 'Nomor',
      hint:      json['hint']       as String? ?? '',
      prefix:    json['prefix']     as String?,
      minLength: json['min_length'] as int? ?? 5,
      maxLength: json['max_length'] as int? ?? 20,
    );
  }

  bool get isPhone   => type == 'phone_number';
  bool get isGameId  => type == 'game_id';
  bool get isAccount => type == 'account_number';
}

class MerchantCategoryInfo {
  final int    id;
  final String code;
  final String name;
  final String colorHex;

  const MerchantCategoryInfo({
    required this.id,
    required this.code,
    required this.name,
    required this.colorHex,
  });

  factory MerchantCategoryInfo.fromJson(Map<String, dynamic> json) {
    return MerchantCategoryInfo(
      id:       json['id']        as int,
      code:     json['code']      as String,
      name:     json['name']      as String,
      colorHex: json['color_hex'] as String? ?? '#1a56db',
    );
  }
}