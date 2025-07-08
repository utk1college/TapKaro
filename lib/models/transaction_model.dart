class Transaction {
  final String transactionId;
  final String senderUserId;
  final String receiverUserId;
  final String amount;
  final String currency;
  final String? description;
  final String? transactionType;
  final String status;
  final DateTime serverTimestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? encryptedData;

  Transaction({
    required this.transactionId,
    required this.senderUserId,
    required this.receiverUserId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.serverTimestamp,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.transactionType,
    this.encryptedData,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        transactionId: json['transaction_id'],
        senderUserId: json['sender_user_id'],
        receiverUserId: json['receiver_user_id'],
        amount: json['amount'],
        currency: json['currency'],
        description: json['description'],
        transactionType: json['transaction_type'],
        status: json['status'],
        serverTimestamp: DateTime.parse(json['server_timestamp']),
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        encryptedData: json['encrypted_data'],
      );
}
