import 'package:flutter/material.dart';
import '../logic/wallet.dart';

class SendScreen extends StatefulWidget {
  final Wallet wallet;
  const SendScreen({super.key, required this.wallet});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final phoneController = TextEditingController();
  final amountController = TextEditingController();
  String? error;

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void send() {
    final result = widget.wallet.send(
      phoneController.text.trim(),
      amountController.text,
    );

    if (result != null) {
      setState(() {
        error = result;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send money')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount (RWF)'),
            ),
            const SizedBox(height: 16),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: send,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}