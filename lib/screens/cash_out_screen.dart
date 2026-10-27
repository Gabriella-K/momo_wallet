import 'package:flutter/material.dart';
import '../logic/wallet.dart';

class CashOutScreen extends StatefulWidget {
  final Wallet wallet;
  const CashOutScreen({super.key, required this.wallet});

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final amountController = TextEditingController();
  String? error;
  Map<int, int>? notes; // null = notes not shown yet
  int amount = 0;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  // Step 1: check the amount and show the notes. Nothing moves yet.
  void showNotes() {
    final result = widget.wallet.checkCashOut(amountController.text);

    if (result != null) {
      setState(() {
        error = result;
        notes = null;
      });
      return;
    }

    final value = int.parse(amountController.text.trim());
    setState(() {
      error = null;
      amount = value;
      notes = widget.wallet.notesFor(value);
    });
  }

  // Step 2: only now does the money move.
  void confirm() {
    widget.wallet.cashOut(amount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash out')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (RWF)'),
              onChanged: (_) {
                // The amount changed, so the notes on screen are out of date.
                setState(() {
                  notes = null;
                  error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: showNotes,
              child: const Text('Show notes'),
            ),
            if (notes != null) ...[
              const SizedBox(height: 24),
              Text('The agent will give you $amount RWF in notes:'),
              const SizedBox(height: 8),
              for (final entry in notes!.entries)
                Text(
                  '${entry.key} × ${entry.value}',
                  style: const TextStyle(fontSize: 18),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: confirm,
                child: const Text('Confirm'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}