class WalletModel {
  final String walletNumber;
  final String walletName;
  final double balance;
  final bool pinSet;
  final String status;

  WalletModel({
    required this.walletNumber,
    required this.walletName,
    required this.balance,
    required this.pinSet,
    required this.status,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletNumber: json['wallet_number'] ?? '',
      walletName:   json['wallet_name']   ?? '',
      balance:      double.parse(json['balance'].toString()),
      pinSet:       json['pin_set'] ?? false,
      status:       json['status'] ?? 'active',
    );
  }
}