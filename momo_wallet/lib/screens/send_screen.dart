
import 'package:flutter/material.dart';
import '../logic/wallet.dart';

class SendScreen extends StatefulWidget {
  final Wallet wallet;

  const SendScreen({
    super.key,
    required this.wallet,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final phoneController = TextEditingController();
  final amountController = TextEditingController();

  String? error;
  bool isSending = false;

  Future<void> sendMoney() async {
    final phone = phoneController.text.trim();
    final amount = int.tryParse(amountController.text.trim());

    if (phone.isEmpty || amount == null) {
      setState(() {
        error = 'Enter a phone number and a valid amount.';
      });
      return;
    }

    setState(() {
      error = null;
      isSending = true;
    });

    try {
      await widget.wallet.send(phone, amount);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Money sent successfully!'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.send,
            size: 60,
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          Text(
            'Available balance: ${widget.wallet.balance} RWF',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Recipient phone number',
              hintText: '0781234567',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (RWF)',
              prefixIcon: Icon(Icons.money),
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: isSending ? null : sendMoney,
            icon: const Icon(Icons.send),
            label: Text(isSending ? 'Sending...' : 'Send Money'),
          ),
        ],
      ),
    );
  }
}
