import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pantry_provider.dart';

class DietaryFilterRow extends StatelessWidget {
  const DietaryFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kAvailableDietaryFilters.map((label) {
        final selected = provider.selectedDietary.contains(label);
        return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => context.read<PantryProvider>().toggleDietary(label),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }
}

class TimeFilterRow extends StatelessWidget {
  const TimeFilterRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kTimeFilterOptions.map((minutes) {
        final selected = provider.selectedMaxMinutes == minutes;
        return ChoiceChip(
          label: Text('Under $minutes min'),
          selected: selected,
          onSelected: (_) =>
              context.read<PantryProvider>().setMaxMinutes(minutes),
        );
      }).toList(),
    );
  }
}

class ServingsStepper extends StatelessWidget {
  const ServingsStepper({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () =>
              context.read<PantryProvider>().setServings(provider.servings - 1),
        ),
        Text('${provider.servings} servings',
            style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () =>
              context.read<PantryProvider>().setServings(provider.servings + 1),
        ),
      ],
    );
  }
}
