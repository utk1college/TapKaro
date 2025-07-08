class Wallet {
  final String walletId;
  final String userId;
  final double balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        walletId: json['wallet_id'],
        userId: json['user_id'],
        balance: (json['balance'] as num).toDouble(),
        currency: json['currency'],
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
}
