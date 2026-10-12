import 'package:flutter/material.dart';

void main() {
  runApp(const ShoppingApp());
}

// The model: one shopping item with a name and a bought status
class Item {
  Item(this.name);
  final String name;
  bool bought = false;
}

// The app: theme and first screen
class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const HomeScreen(title: 'Shopping List'),
    );
  }
}

// The screen's settings (the title never changes)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// The screen's data and logic (this part changes)
class _HomeScreenState extends State<HomeScreen> {
  final items = [Item('Milk'), Item('Bread'), Item('Rice')];
  final controller = TextEditingController();

  void addItem() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type an item first')),
      );
      return;
    }
    setState(() {
      items.add(Item(text));
    });
    controller.clear();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = items.where((item) => !item.bought).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} ($left left)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            onPressed: () {
              setState(() {
                items.removeWhere((item) => item.bought);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Add an item'),
                    onSubmitted: (_) => addItem(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(onPressed: addItem, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(
                    item.bought ? Icons.check_circle : Icons.shopping_basket,
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration:
                      item.bought ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        items.removeAt(index);
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      item.bought = !item.bought;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}