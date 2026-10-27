class Transaction {
  final String description;
  final int amount;
  final bool isIn;

  Transaction({
    required this.description,
    required this.amount,
    required this.isIn,
  });
}