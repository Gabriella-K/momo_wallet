
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../logic/wallet.dart';
import '../logic/rate_service.dart';
import '../models/transaction.dart';
import 'send_screen.dart';
import 'cash_out_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late final Wallet wallet;

  StreamSubscription<List<Transaction>>? transactionSubscription;

  double? rate;
  bool rateLoading = true;
  String? rateError;
  bool walletLoading = true;

  String selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();

    wallet = Wallet();
    initializeWallet();
  }

  Future<void> initializeWallet() async {
    try {
      // Load the initial transactions.
      await wallet.load();

      if (!mounted) return;

      // Listen for live Firestore updates.
      transactionSubscription = wallet.watchTransactions().listen(
            (updatedTransactions) {
          if (!mounted) return;

          setState(() {
            wallet.transactions = updatedTransactions;
            walletLoading = false;
          });
        },
        onError: (error) {
          debugPrint('Live transaction error: $error');

          if (!mounted) return;

          setState(() {
            walletLoading = false;
          });
        },
      );
    } catch (e) {
      debugPrint('Wallet loading error: $e');

      if (!mounted) return;

      setState(() {
        walletLoading = false;
      });
    }

    await loadRate();
  }

  @override
  void dispose() {
    transactionSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadRate() async {
    if (!mounted) return;

    setState(() {
      rateLoading = true;
      rateError = null;
    });

    try {
      final result = await fetchRate();

      if (!mounted) return;

      setState(() {
        rate = result;
        rateLoading = false;
        rateError = null;
      });
    } catch (e) {
      debugPrint('Could not load exchange rate: $e');

      if (!mounted) return;

      setState(() {
        rateLoading = false;
        rateError =
        'Could not load the exchange rate. '
            'Check your internet connection and try again.';
      });
    }
  }

  Widget rateCard() {
    if (rateLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading live exchange rate...'),
            ],
          ),
        ),
      );
    }

    if (rateError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off,
                size: 52,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'No internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rateError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: rateLoading ? null : loadRate,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.currency_exchange,
              size: 32,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            const Text(
              'LIVE EXCHANGE RATE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1 USD = ${rate!.toStringAsFixed(2)} RWF',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Rates by ExchangeRate-API',
              style: TextStyle(fontSize: 11),
            ),
            TextButton.icon(
              onPressed: rateLoading ? null : loadRate,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh rate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> receiveMoney() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Receive Money'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. Money from a friend',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (RWF)',
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final description =
                    descriptionController.text.trim();

                    final amount =
                    int.tryParse(amountController.text.trim());

                    if (description.isEmpty) {
                      setDialogState(() {
                        errorMessage =
                        'Please enter a description.';
                      });
                      return;
                    }

                    if (amount == null || amount <= 0) {
                      setDialogState(() {
                        errorMessage =
                        'Enter a valid positive amount.';
                      });
                      return;
                    }

                    try {
                      await wallet.receive(description, amount);

                      if (!dialogContext.mounted) return;

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      setDialogState(() {
                        errorMessage = e
                            .toString()
                            .replaceFirst('Exception: ', '');
                      });
                    }
                  },
                  child: const Text('Receive'),
                ),
              ],
            );
          },
        );
      },
    );

    descriptionController.dispose();
    amountController.dispose();

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> openSendScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendScreen(wallet: wallet),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> openCashOutScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CashOutScreen(wallet: wallet),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    final removed = await wallet.deleteTransaction(transaction);

    if (!mounted) return;

    setState(() {});

    if (!removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This transaction cannot be deleted because '
                'it would make your balance invalid.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted.'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () async {
            await wallet.restoreTransaction(transaction);

            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  List<Transaction> get filteredTransactions {
    final transactions = wallet.transactions.reversed.toList();

    if (selectedFilter == 'IN') {
      return transactions.where((t) => t.isIn).toList();
    }

    if (selectedFilter == 'OUT') {
      return transactions.where((t) => !t.isIn).toList();
    }

    return transactions;
  }

  Widget statisticCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 25),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget transactionTile(Transaction transaction) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isIn
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.red.withValues(alpha: 0.12),
          child: Icon(
            transaction.isIn
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: transaction.isIn
                ? Colors.green
                : Colors.red,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          transaction.isIn ? 'Money received' : 'Money sent',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${transaction.isIn ? '+' : '-'}'
                  '${transaction.amount} RWF',
              style: TextStyle(
                color: transaction.isIn
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: 'Delete transaction',
              onPressed: () => deleteTransaction(transaction),
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (walletLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('4MoMo Wallet'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('4MoMo Wallet'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: loadRate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.green.shade700,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'AVAILABLE BALANCE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${wallet.balance} RWF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your money, your control.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            rateCard(),

            const SizedBox(height: 12),

            const Text(
              'Wallet Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            Row(
              children: [
                statisticCard(
                  'Money In',
                  '${wallet.totalIn} RWF',
                  Icons.south_west,
                ),
                statisticCard(
                  'Money Out',
                  '${wallet.totalOut} RWF',
                  Icons.north_east,
                ),
              ],
            ),

            Row(
              children: [
                statisticCard(
                  'Lowest Balance',
                  '${wallet.lowestBalance} RWF',
                  Icons.account_balance_wallet_outlined,
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'Wallet Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: receiveMoney,
                    icon: const Icon(Icons.call_received),
                    label: const Text('Receive'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: openSendScreen,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: openCashOutScreen,
                    icon: const Icon(Icons.money),
                    label: const Text('Cash Out'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'ALL',
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: 'IN',
                  label: Text('IN'),
                ),
                ButtonSegment(
                  value: 'OUT',
                  label: Text('OUT'),
                ),
              ],
              selected: {selectedFilter},
              onSelectionChanged: (selection) {
                setState(() {
                  selectedFilter = selection.first;
                });
              },
            ),

            const SizedBox(height: 8),

            if (filteredTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No transactions to show.'),
                ),
              )
            else
              ...filteredTransactions.map(transactionTile),
          ],
        ),
      ),
    );
  }
}
