class Transaction {
  final String description;
  final int amount;
  final bool isIn;

  Transaction({
    required this.description,
    required this.amount,
    required this.isIn,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'isIn': isIn,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      description: json['description'] as String,
      amount: (json['amount'] as num).toInt(),
      isIn: json['isIn'] as bool,
    );
  }
}