
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction.dart';

class Wallet {
  final int startBalance = 10000;

  List<Transaction> transactions = [];

  final List<int> notes = [5000, 2000, 1000, 500, 100];

  // Get the signed-in user's transaction collection.
  CollectionReference<Map<String, dynamic>> get transactionCollection {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please sign in to access your wallet.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  // Load the signed-in user's transactions.
  Future<void> load() async {
    final snapshot = await transactionCollection
        .orderBy('createdAt')
        .get();

    transactions = snapshot.docs.map((document) {
      return Transaction.fromJson(
        document.data(),
        id: document.id,
      );
    }).toList();
  }

  // Listen for live transaction updates from Firestore.
  Stream<List<Transaction>> watchTransactions() {
    return transactionCollection
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((document) {
        return Transaction.fromJson(
          document.data(),
          id: document.id,
        );
      }).toList();
    });
  }

  // Save a new transaction in Firestore.
  Future<void> addTransaction(Transaction transaction) async {
    final document = await transactionCollection.add({
      'description': transaction.description,
      'amount': transaction.amount,
      'isIn': transaction.isIn,
      'createdAt': Timestamp.fromDate(transaction.createdAt),
    });

    transactions.add(
      Transaction(
        id: document.id,
        description: transaction.description,
        amount: transaction.amount,
        isIn: transaction.isIn,
        createdAt: transaction.createdAt,
      ),
    );
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
  Future<void> receive(String description, dynamic amount) async {
    final cleanDescription = description.trim();
    final parsedAmount = int.tryParse(amount.toString().trim());

    if (cleanDescription.isEmpty) {
      throw Exception('Please enter a description.');
    }

    if (parsedAmount == null || parsedAmount <= 0) {
      throw Exception('Enter a valid positive amount.');
    }

    await addTransaction(
      Transaction(
        description: cleanDescription,
        amount: parsedAmount,
        isIn: true,
      ),
    );
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

    await addTransaction(
      Transaction(
        description: 'Sent to $cleanPhone',
        amount: parsedAmount,
        isIn: false,
      ),
    );
  }

  // Check whether an amount can be paid using available banknotes.
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

    if (remaining != 0) {
      return [];
    }

    return selectedNotes;
  }

  // Validate a cash-out amount.
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

    await addTransaction(
      Transaction(
        description: 'Cash out',
        amount: amount,
        isIn: false,
      ),
    );
  }

  // Delete a transaction by its index.
  Future<bool> delete(int index) async {
    if (index < 0 || index >= transactions.length) {
      return false;
    }

    final transaction = transactions[index];

    final remainingTransactions = List<Transaction>.from(transactions);
    remainingTransactions.removeAt(index);

    int calculatedBalance = startBalance;

    for (final item in remainingTransactions) {
      calculatedBalance += item.isIn ? item.amount : -item.amount;

      if (calculatedBalance < 0) {
        return false;
      }
    }

    if (transaction.id.isEmpty) {
      throw Exception('This transaction has no Firestore document ID.');
    }

    await transactionCollection.doc(transaction.id).delete();

    transactions.removeAt(index);

    return true;
  }

  // Restore a deleted transaction.
  Future<void> restore(int index, Transaction transaction) async {
    if (transaction.id.isEmpty) {
      await addTransaction(transaction);
      return;
    }

    await transactionCollection.doc(transaction.id).set({
      'description': transaction.description,
      'amount': transaction.amount,
      'isIn': transaction.isIn,
      'createdAt': Timestamp.fromDate(transaction.createdAt),
    });

    final safeIndex = index.clamp(0, transactions.length);
    transactions.insert(safeIndex, transaction);
  }

  // Compatibility method for screens that delete by Transaction object.
  Future<bool> deleteTransaction(Transaction transaction) async {
    final index = transactions.indexWhere(
          (item) => item.id == transaction.id,
    );

    if (index == -1) {
      return false;
    }

    return delete(index);
  }

  // Compatibility method for screens that restore by Transaction object.
  Future<void> restoreTransaction(Transaction transaction) async {
    await restore(transactions.length, transaction);
  }

  // Edit an existing transaction.
  Future<void> updateTransaction(Transaction transaction) async {
    if (transaction.id.isEmpty) {
      throw Exception('This transaction has no Firestore document ID.');
    }

    await transactionCollection.doc(transaction.id).update({
      'description': transaction.description,
      'amount': transaction.amount,
      'isIn': transaction.isIn,
    });

    final index = transactions.indexWhere(
          (item) => item.id == transaction.id,
    );

    if (index != -1) {
      transactions[index] = transaction;
    }
  }
}