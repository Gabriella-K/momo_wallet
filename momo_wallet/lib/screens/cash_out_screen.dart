import 'package:flutter/material.dart';
import '../logic/wallet.dart';

class CashOutScreen extends StatefulWidget {
  final Wallet wallet;

  const CashOutScreen({
    super.key,
    required this.wallet,
  });

  @override
  State<CashOutScreen> createState() => _CashOutScreenState();
}

class _CashOutScreenState extends State<CashOutScreen> {
  final amountController = TextEditingController();
  List<int> notes = [];
  String? errorMessage;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void confirmCashOut() {
    final amount = int.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() {
        errorMessage = 'Enter a valid positive whole amount.';
        notes = [];
      });
      return;
    }

    if (amount > widget.wallet.balance) {
      setState(() {
        errorMessage = 'Insufficient wallet balance.';
        notes = [];
      });
      return;
    }

    final calculatedNotes = widget.wallet.notesFor(amount);

    if (calculatedNotes.isEmpty) {
      setState(() {
        errorMessage = 'This amount cannot be paid using available notes.';
        notes = [];
      });
      return;
    }

    setState(() {
      errorMessage = null;
      notes = calculatedNotes;
    });

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Cash Out'),
        content: Text(
          'Cash out $amount RWF?\n'
              'Notes to give the agent: ${calculatedNotes.join(', ')} RWF',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await widget.wallet.cashOut(amount);

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cash out successful!'),
                  ),
                );

                Navigator.pop(context, true);
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cash out failed: $e')),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash Out')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available balance: ${widget.wallet.balance} RWF',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (RWF)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {
                  errorMessage = null;
                  notes = [];
                });
              },
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            if (notes.isNotEmpty) ...[
              const Text(
                'Notes to give the agent:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(notes.map((note) => '$note RWF').join('\n')),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: confirmCashOut,
                child: const Text('Confirm Cash Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}