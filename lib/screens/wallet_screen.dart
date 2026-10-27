import 'package:flutter/material.dart';
import '../logic/wallet.dart';
import 'send_screen.dart';
import 'cash_out_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final Wallet wallet = Wallet();
  String filter = 'All';

  final Color green = Colors.green.shade700;
  final Color red = Colors.red.shade700;

  void showMessage(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Open another screen, then redraw this one when we come back.
  Future<void> openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    setState(() {});
  }

  void deleteTransaction(int index) {
    final t = wallet.transactions[index];
    final error = wallet.delete(index);
    if (error != null) {
      showMessage(error);
      return;
    }
    setState(() {});

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            wallet.restore(index, t);
            setState(() {});
          },
        ),
      ),
    );
  }

  void showReceiveDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Receive money'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount (RWF)'),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!, style: TextStyle(color: red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final result = wallet.receive(
                      descController.text,
                      amountController.text,
                    );
                    if (result != null) {
                      setDialogState(() {
                        error = result;
                      });
                    } else {
                      Navigator.pop(dialogContext);
                      setState(() {});
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget statBox(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Real positions of the transactions to show, newest first.
    final List<int> visible = [];
    for (int i = wallet.transactions.length - 1; i >= 0; i--) {
      final t = wallet.transactions[i];
      if (filter == 'All' ||
          (filter == 'IN' && t.isIn) ||
          (filter == 'OUT' && !t.isIn)) {
        visible.add(i);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('4MoMo Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance card
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Balance'),
                    const SizedBox(height: 8),
                    Text(
                      '${wallet.balance} RWF',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Statistics
            Row(
              children: [
                statBox('Total IN', '${wallet.totalIn}'),
                statBox('Total OUT', '${wallet.totalOut}'),
                statBox('Lowest balance', '${wallet.lowestBalance}'),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => openScreen(SendScreen(wallet: wallet)),
                  child: const Text('Send'),
                ),
                ElevatedButton(
                  onPressed: () => openScreen(CashOutScreen(wallet: wallet)),
                  child: const Text('Cash out'),
                ),
                ElevatedButton(
                  onPressed: showReceiveDialog,
                  child: const Text('Receive'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(value: 'IN', label: Text('IN')),
                ButtonSegment(value: 'OUT', label: Text('OUT')),
              ],
              selected: {filter},
              onSelectionChanged: (selection) {
                setState(() {
                  filter = selection.first;
                });
              },
            ),
            const SizedBox(height: 8),

            // Transactions
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, position) {
                  final index = visible[position];
                  final t = wallet.transactions[index];
                  final color = t.isIn ? green : red;

                  return ListTile(
                    title: Text(t.description),
                    subtitle: Text(
                      t.isIn ? 'IN' : 'OUT',
                      style: TextStyle(color: color),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${t.amount} RWF',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => deleteTransaction(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}