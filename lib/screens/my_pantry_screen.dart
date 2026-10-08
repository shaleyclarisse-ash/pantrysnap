import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pantry_models.dart';
import '../models/recipe.dart';
import '../services/local_providers.dart';
import '../services/pantry_provider.dart';
import 'loading_screen.dart';

class MyPantryScreen extends StatelessWidget {
  const MyPantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryInventoryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pantry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add ingredient',
            onPressed: () => _showAddEditSheet(context),
          ),
        ],
      ),
      body: pantry.items.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.kitchen_outlined,
                  size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                "Your pantry is empty. Add what you have on hand, "
                    "or scan a photo to detect items automatically.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pantry.expired.isNotEmpty) ...[
            _SectionLabel(
                label: 'Expired', color: theme.colorScheme.error),
            ...pantry.expired.map((item) => _PantryTile(item: item)),
            const SizedBox(height: 16),
          ],
          if (pantry.expiringSoon.isNotEmpty) ...[
            _SectionLabel(
                label: 'Expiring soon',
                color: theme.colorScheme.secondary),
            ...pantry.expiringSoon
                .map((item) => _PantryTile(item: item)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Use ingredients soon'),
                onPressed: () => _useIngredientsSoon(context, pantry),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _SectionLabel(label: 'Everything'),
          ...pantry.items.map((item) => _PantryTile(item: item)),
        ],
      ),
    );
  }

  void _useIngredientsSoon(
      BuildContext context, PantryInventoryProvider pantry) {
    final scanProvider = context.read<PantryProvider>();
    scanProvider.detectedIngredients = pantry.expiringSoon
        .map((p) => Ingredient(name: p.name, quantity: p.quantity))
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoadingScreen(mode: LoadingMode.generateRecipes),
      ),
    );
  }

  Future<void> _showAddEditSheet(BuildContext context,
      [PantryItem? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final quantityController =
    TextEditingController(text: existing?.quantity ?? '');
    String category = existing?.category ?? kPantryCategories.first;
    DateTime? expiryDate = existing?.expiryDate;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Add ingredient' : 'Edit ingredient',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: existing == null,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: kPantryCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setSheetState(() => category = value ?? category),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expiryDate == null
                          ? 'No expiry date set'
                          : 'Expires ${expiryDate!.month}/${expiryDate!.day}/${expiryDate!.year}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expiryDate ?? DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                        lastDate:
                        DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) {
                        setSheetState(() => expiryDate = picked);
                      }
                    },
                    child: const Text('Set date'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final provider = context.read<PantryInventoryProvider>();
                  if (existing == null) {
                    provider.addItem(
                      name: nameController.text.trim(),
                      quantity: quantityController.text.trim().isEmpty
                          ? '1'
                          : quantityController.text.trim(),
                      category: category,
                      expiryDate: expiryDate,
                    );
                  } else {
                    existing.name = nameController.text.trim();
                    existing.quantity = quantityController.text.trim();
                    existing.category = category;
                    existing.expiryDate = expiryDate;
                    provider.updateItem(existing);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;
  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: color),
      ),
    );
  }
}

class _PantryTile extends StatelessWidget {
  final PantryItem item;
  const _PantryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = item.daysUntilExpiry;

    String? expiryLabel;
    Color? expiryColor;
    if (days != null) {
      if (days < 0) {
        expiryLabel = 'Expired ${-days}d ago';
        expiryColor = theme.colorScheme.error;
      } else if (days == 0) {
        expiryLabel = 'Expires today';
        expiryColor = theme.colorScheme.secondary;
      } else if (days <= 3) {
        expiryLabel = 'Expires in ${days}d';
        expiryColor = theme.colorScheme.secondary;
      } else {
        expiryLabel = 'Expires in ${days}d';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('${item.quantity} · ${item.category}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (expiryLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(expiryLabel,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: expiryColor)),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  context.read<PantryInventoryProvider>().removeItem(item.id),
            ),
          ],
        ),
      ),
    );
  }
}
