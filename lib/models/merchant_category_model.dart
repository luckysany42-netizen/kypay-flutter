class MerchantCategoryModel {
  final int    id;
  final String code;
  final String name;
  final String? iconUrl;
  final String colorHex;
  final int    merchantCount;

  const MerchantCategoryModel({
    required this.id,
    required this.code,
    required this.name,
    this.iconUrl,
    required this.colorHex,
    this.merchantCount = 0,
  });

  factory MerchantCategoryModel.fromJson(Map<String, dynamic> json) {
    return MerchantCategoryModel(
      id:            json['id'] as int,
      code:          json['code'] as String,
      name:          json['name'] as String,
      iconUrl:       json['icon_url'] as String?,
      colorHex:      json['color_hex'] as String? ?? '#1a56db',
      merchantCount: json['merchant_count'] as int? ?? 0,
    );
  }

  // Icon fallback berdasarkan code kategori
  String get iconFallback {
    return switch (code) {
      'game'    => '🎮',
      'pulsa'   => '📱',
      'tagihan' => '📄',
      'rumah'   => '🏠',
      'hiburan' => '🎵',
      _         => '💳',
    };
  }
}