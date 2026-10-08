import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/local_providers.dart';
import '../services/storage_service.dart';
import 'shopping_list_screen.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  int _selectedDay = DateTime.now().weekday - 1; // 0 = Monday

  @override
  Widget build(BuildContext context) {
    final mealPlan = context.watch<MealPlanProvider>();
    final theme = Theme.of(context);
    final dayEntries = mealPlan.forDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Shopping list from plan',
            onPressed: () => _generateShoppingList(context, mealPlan),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: kDaysOfWeek.length,
              itemBuilder: (context, index) {
                final selected = index == _selectedDay;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(kDaysOfWeek[index].substring(0, 3)),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDay = index),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: kMealTypes.map((mealType) {
                final entry = dayEntries
                    .where((e) => e.mealType == mealType)
                    .firstOrNull;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(mealType,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                    subtitle: Text(
                      entry != null ? entry.recipe.title : 'Nothing planned',
                      style: theme.textTheme.bodyLarge,
                    ),
                    trailing: entry != null
                        ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context
                          .read<MealPlanProvider>()
                          .removeEntry(entry.id),
                    )
                        : IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          _pickRecipe(context, mealType),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRecipe(BuildContext context, String mealType) async {
    final saved = StorageService.instance.getAllSaved();
    final history = StorageService.instance.getHistory();
    final seen = <String>{};
    final options = <Recipe>[];
    for (final r in [...saved, ...history]) {
      if (seen.add(r.id)) options.add(r);
    }

    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Generate or save a recipe first to plan with it.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: options.length,
          itemBuilder: (context, index) {
            final recipe = options[index];
            return ListTile(
              title: Text(recipe.title),
              subtitle: Text('${recipe.totalTimeMinutes} min'),
              onTap: () => Navigator.pop(context, recipe),
            );
          },
        ),
      ),
    );

    if (picked == null || !context.mounted) return;
    await context.read<MealPlanProvider>().assignRecipe(
      dayOfWeek: _selectedDay,
      mealType: mealType,
      recipe: picked,
    );
  }

  Future<void> _generateShoppingList(
      BuildContext context, MealPlanProvider mealPlan) async {
    final ingredients = mealPlan.collectWeeklyIngredients();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan some meals first.')),
      );
      return;
    }
    final shoppingProvider = context.read<ShoppingListProvider>();
    for (final ingredient in ingredients) {
      await shoppingProvider.addItem(ingredient.name, ingredient.quantity,
          sourceRecipeTitle: 'Meal Plan');
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
