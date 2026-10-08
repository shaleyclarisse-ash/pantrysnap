import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/local_providers.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingListProvider>();
    final theme = Theme.of(context);

    final unchecked = shopping.items.where((i) => !i.checked).toList();
    final checked = shopping.items.where((i) => i.checked).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (checked.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.checklist_rtl),
              tooltip: 'Clear checked',
              onPressed: () =>
                  context.read<ShoppingListProvider>().clearChecked(),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: shopping.items.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                "Nothing on your list yet. Add items manually, or "
                    "tap \"Add Missing Ingredients\" on any recipe.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ...unchecked.map((item) => CheckboxListTile(
            value: item.checked,
            onChanged: (_) => context
                .read<ShoppingListProvider>()
                .toggleChecked(item),
            title: Text(item.name),
            subtitle: Text(
              item.sourceRecipeTitle != null
                  ? '${item.quantity} · from ${item.sourceRecipeTitle}'
                  : item.quantity,
            ),
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => context
                  .read<ShoppingListProvider>()
                  .removeItem(item.id),
            ),
          )),
          if (checked.isNotEmpty) ...[
            Padding(
              padding:
              const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Checked off',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            ...checked.map((item) => CheckboxListTile(
              value: item.checked,
              onChanged: (_) => context
                  .read<ShoppingListProvider>()
                  .toggleChecked(item),
              title: Text(
                item.name,
                style: const TextStyle(
                    decoration: TextDecoration.lineThrough),
              ),
              subtitle: Text(item.quantity),
              secondary: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => context
                    .read<ShoppingListProvider>()
                    .removeItem(item.id),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              context.read<ShoppingListProvider>().addItem(
                nameController.text.trim(),
                quantityController.text.trim().isEmpty
                    ? '1'
                    : quantityController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
