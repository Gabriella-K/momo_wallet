
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';

class Wallet {
  final int startBalance = 10000;

  List<Transaction> transactions = [];

  final List<int> notes = [5000, 2000, 1000, 500, 100];

  static const String storageKey = 'wallet_transactions';

  // Load saved transactions, or create sample transactions for a new wallet.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTransactions = prefs.getString(storageKey);

    if (savedTransactions != null) {
      final List<dynamic> decoded = jsonDecode(savedTransactions);

      transactions = decoded.map((item) {
        return Transaction.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    } else {
      transactions = [
        Transaction(
          description: 'Salary',
          amount: 5000,
          isIn: true,
        ),
        Transaction(
          description: 'Sent to 0788123456',
          amount: 1500,
          isIn: false,
        ),
        Transaction(
          description: 'Cash out',
          amount: 3500,
          isIn: false,
        ),
      ];

      await save();
    }
  }

  // Save transactions on the device.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      transactions.map((transaction) => transaction.toJson()).toList(),
    );

    await prefs.setString(storageKey, encoded);
  }

  // Calculate the current wallet balance.
  int get balance {
    int result = startBalance;

    for (final transaction in transactions) {
      result += transaction.isIn
          ? transaction.amount
          : -transaction.amount;
    }

    return result;
  }

  // Calculate total money received.
  int get totalIn {
    return transactions
        .where((transaction) => transaction.isIn)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  // Calculate total money sent or withdrawn.
  int get totalOut {
    return transactions
        .where((transaction) => !transaction.isIn)
        .fold(0, (sum, transaction) => sum + transaction.amount);
  }

  // Find the lowest balance recorded through the transaction history.
  int get lowestBalance {
    int currentBalance = startBalance;
    int lowest = startBalance;

    for (final transaction in transactions) {
      currentBalance += transaction.isIn
          ? transaction.amount
          : -transaction.amount;

      if (currentBalance < lowest) {
        lowest = currentBalance;
      }
    }

    return lowest;
  }

  // Receive money.
  // Accepts either an int or a numeric String for compatibility with screens.
  Future<void> receive(String description, dynamic amount) async {
    final cleanDescription = description.trim();
    final parsedAmount = int.tryParse(amount.toString().trim());

    if (cleanDescription.isEmpty) {
      throw Exception('Please enter a description.');
    }

    if (parsedAmount == null || parsedAmount <= 0) {
      throw Exception('Enter a valid positive amount.');
    }

    transactions.add(
      Transaction(
        description: cleanDescription,
        amount: parsedAmount,
        isIn: true,
      ),
    );

    await save();
  }

  // Send money to a phone number.
  Future<void> send(String phone, dynamic amount) async {
    final cleanPhone = phone.trim();
    final parsedAmount = int.tryParse(amount.toString().trim());

    if (!RegExp(r'^07[89]\d{7}$').hasMatch(cleanPhone)) {
      throw Exception(
        'Enter a valid 10-digit phone number starting with 078 or 079.',
      );
    }

    if (parsedAmount == null || parsedAmount < 100) {
      throw Exception('The minimum sending amount is 100 RWF.');
    }

    if (parsedAmount > balance) {
      throw Exception('Insufficient balance.');
    }

    transactions.add(
      Transaction(
        description: 'Sent to $cleanPhone',
        amount: parsedAmount,
        isIn: false,
      ),
    );

    await save();
  }

  // Check whether an amount can be paid using the available banknotes.
  List<int> notesFor(int amount) {
    if (amount <= 0) return [];

    int remaining = amount;
    final List<int> selectedNotes = [];

    for (final note in notes) {
      while (remaining >= note) {
        selectedNotes.add(note);
        remaining -= note;
      }
    }

    // Return no notes if the exact amount cannot be made.
    if (remaining != 0) {
      return [];
    }

    return selectedNotes;
  }

  // Validate a cash-out amount supplied as text.
  bool checkCashOut(String amount) {
    final parsedAmount = int.tryParse(amount.trim());

    if (parsedAmount == null || parsedAmount <= 0) {
      return false;
    }

    if (parsedAmount > balance) {
      return false;
    }

    return notesFor(parsedAmount).isNotEmpty;
  }

  // Cash out money.
  Future<void> cashOut(int amount) async {
    if (amount <= 0) {
      throw Exception('Enter a valid cash-out amount.');
    }

    if (amount > balance) {
      throw Exception('Insufficient balance.');
    }

    if (notesFor(amount).isEmpty) {
      throw Exception(
        'This amount cannot be paid using the available banknotes.',
      );
    }

    transactions.add(
      Transaction(
        description: 'Cash out',
        amount: amount,
        isIn: false,
      ),
    );

    await save();
  }

  // Delete a transaction by its index in the original list.
  Future<bool> delete(int index) async {
    if (index < 0 || index >= transactions.length) {
      return false;
    }

    final remainingTransactions = List<Transaction>.from(transactions);
    remainingTransactions.removeAt(index);

    int calculatedBalance = startBalance;

    for (final transaction in remainingTransactions) {
      calculatedBalance += transaction.isIn
          ? transaction.amount
          : -transaction.amount;

      if (calculatedBalance < 0) {
        return false;
      }
    }

    transactions.removeAt(index);
    await save();

    return true;
  }

  // Restore a previously deleted transaction at its original position.
  Future<void> restore(int index, Transaction transaction) async {
    final safeIndex = index.clamp(0, transactions.length);

    transactions.insert(safeIndex, transaction);
    await save();
  }

  // Compatibility method for screens that delete by Transaction object.
  Future<bool> deleteTransaction(Transaction transaction) async {
    final index = transactions.indexOf(transaction);

    if (index == -1) {
      return false;
    }

    return delete(index);
  }

  // Compatibility method for screens that restore by Transaction object.
  Future<void> restoreTransaction(Transaction transaction) async {
    transactions.add(transaction);
    await save();
  }
}
