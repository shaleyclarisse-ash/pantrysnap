import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/pantry_provider.dart';
import 'loading_screen.dart';

/// Shown after ingredient detection: "Camera -> AI Detection -> Confirm
/// Ingredients -> Preferences -> Generate Recipes". Lets the user add,
/// remove, or fix anything the AI got wrong before recipes are generated.
class IngredientConfirmScreen extends StatelessWidget {
  const IngredientConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final ingredients = provider.detectedIngredients;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm ingredients')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                "Here's what we spotted. Add anything we missed, or remove "
                    "anything that's not actually there.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: ingredients.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "We couldn't confidently identify anything. "
                        "Try adding ingredients manually below.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = ingredients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(ingredient.name),
                      subtitle: Text(ingredient.quantity),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editIngredient(
                                context, index, ingredient),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => context
                                .read<PantryProvider>()
                                .removeDetectedIngredient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add ingredient'),
                    onPressed: () => _editIngredient(context, null, null),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Recipes'),
                    onPressed: ingredients.isEmpty
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoadingScreen(
                              mode: LoadingMode.generateRecipes),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editIngredient(
      BuildContext context, int? index, Ingredient? existing) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final quantityController =
    TextEditingController(text: existing?.quantity ?? '');

    final result = await showDialog<Ingredient>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add ingredient' : 'Edit ingredient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration:
              const InputDecoration(labelText: 'Quantity (e.g. "2 cups")'),
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
              Navigator.pop(
                context,
                Ingredient(
                  name: nameController.text.trim(),
                  quantity: quantityController.text.trim().isEmpty
                      ? 'to taste'
                      : quantityController.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) return;
    final provider = context.read<PantryProvider>();
    if (index == null) {
      provider.addDetectedIngredient(result);
    } else {
      provider.updateDetectedIngredient(index, result);
    }
  }
}
