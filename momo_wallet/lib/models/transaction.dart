import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String description;
  final int amount;
  final bool isIn;
  final DateTime createdAt;

  Transaction({
    this.id = '',
    required this.description,
    required this.amount,
    required this.isIn,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'amount': amount,
      'isIn': isIn,
      'createdAt': createdAt,
    };
  }

  factory Transaction.fromJson(
      Map<String, dynamic> json, {
        String id = '',
      }) {
    final savedDate = json['createdAt'];

    return Transaction(
      id: id,
      description: json['description'] as String,
      amount: (json['amount'] as num).toInt(),
      isIn: json['isIn'] as bool,
      createdAt: savedDate is DateTime
          ? savedDate
          : savedDate is Timestamp
          ? savedDate.toDate()
          : DateTime.now(),
    );
  }

  Transaction copyWith({
    String? description,
    int? amount,
    bool? isIn,
  }) {
    return Transaction(
      id: id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      isIn: isIn ?? this.isIn,
      createdAt: createdAt,
    );
  }
}
