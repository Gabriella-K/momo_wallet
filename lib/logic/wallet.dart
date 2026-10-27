import '../models/transaction.dart';



class Wallet {
  final int startBalance = 10000;

  // Stored oldest -> newest. The screen reverses it to show newest first.
  final List<Transaction> transactions = [
    Transaction(description: 'Salary', amount: 5000, isIn: true),
    Transaction(description: 'Sent to 0788123456', amount: 1500, isIn: false),
    Transaction(description: 'Cash out', amount: 3500, isIn: false),
  ];

  final List<int> notes = [5000, 2000, 1000, 500, 100];

  // ---------- Balance (never stored, always calculated) ----------

  int get balance {
    int b = startBalance;
    for (final t in transactions) {
      b += t.isIn ? t.amount : -t.amount;
    }
    return b;
  }

  // ---------- Checking an amount ----------

  String? checkAmount(String text) {
    final amount = int.tryParse(text.trim());
    if (amount == null || amount <= 0) {
      return 'Amount must be a whole number above 0';
    }
    return null;
  }

  // ---------- Receiving money ----------

  String? receive(String description, String amountText) {
    if (description.trim().isEmpty) {
      return 'Description cannot be empty';
    }
    final error = checkAmount(amountText);
    if (error != null) return error;

    transactions.add(Transaction(
      description: description.trim(),
      amount: int.parse(amountText.trim()),
      isIn: true,
    ));
    return null;
  }

  // ---------- Sending money ----------

  String? send(String phone, String amountText) {
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Phone number must be exactly 10 digits';
    }
    if (!phone.startsWith('078') && !phone.startsWith('079')) {
      return 'Phone number must start with 078 or 079';
    }
    final error = checkAmount(amountText);
    if (error != null) return error;

    final amount = int.parse(amountText.trim());
    if (amount < 100) {
      return 'Minimum amount is 100 RWF';
    }
    if (amount > balance) {
      return 'Insufficient balance';
    }

    transactions.add(Transaction(
      description: 'Sent to $phone',
      amount: amount,
      isIn: false,
    ));
    return null;
  }

  // ---------- Cashing out ----------

  // Step 1: only checks, changes nothing.
  String? checkCashOut(String amountText) {
    final error = checkAmount(amountText);
    if (error != null) return error;

    final amount = int.parse(amountText.trim());
    if (amount % 100 != 0) {
      return 'Amount must be a multiple of 100';
    }
    if (amount > balance) {
      return 'Insufficient balance';
    }
    return null;
  }

  // Which notes the agent hands out, biggest first.
  Map<int, int> notesFor(int amount) {
    final result = <int, int>{};
    for (final note in notes) {
      final count = amount ~/ note;
      if (count > 0) {
        result[note] = count;
      }
      amount = amount % note;
    }
    return result;
  }

  // Step 2: called only when the user presses Confirm.
  void cashOut(int amount) {
    transactions.add(Transaction(
      description: 'Cash out',
      amount: amount,
      isIn: false,
    ));
  }

  // ---------- Statistics ----------

  int get totalIn {
    int total = 0;
    for (final t in transactions) {
      if (t.isIn) total += t.amount;
    }
    return total;
  }

  int get totalOut {
    int total = 0;
    for (final t in transactions) {
      if (!t.isIn) total += t.amount;
    }
    return total;
  }

  int get lowestBalance {
    int current = startBalance;
    int lowest = startBalance;
    for (final t in transactions) {
      current += t.isIn ? t.amount : -t.amount;
      if (current < lowest) lowest = current;
    }
    return lowest;
  }

  // ---------- Delete and Undo ----------

  String? delete(int index) {
    int b = startBalance;
    for (int i = 0; i < transactions.length; i++) {
      if (i == index) continue;
      final t = transactions[i];
      b += t.isIn ? t.amount : -t.amount;
      if (b < 0) {
        return 'Cannot delete: the balance would go below 0';
      }
    }
    transactions.removeAt(index);
    return null;
  }

  void restore(int index, Transaction t) {
    transactions.insert(index, t);
  }
}