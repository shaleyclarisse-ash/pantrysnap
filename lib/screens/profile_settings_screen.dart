import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/local_providers.dart';
import '../services/pantry_provider.dart';
import '../services/storage_service.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final firebaseUser = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person,
                    color: theme.colorScheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firebaseUser?.displayName?.isNotEmpty == true
                          ? firebaseUser!.displayName!
                          : (profile.name.isNotEmpty
                          ? profile.name
                          : 'PantrySnap User'),
                      style: theme.textTheme.titleLarge,
                    ),
                    if (firebaseUser?.email != null)
                      Text(firebaseUser!.email!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Cooking preferences'),
          const SizedBox(height: 8),
          Text('Dietary preferences', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _MultiChipEditor(
            options: kAvailableDietaryFilters,
            selected: profile.dietaryPreferences,
            onChanged: (values) =>
                profile.updateProfile(dietaryPreferences: values),
          ),
          const SizedBox(height: 20),
          Text('Allergies', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _FreeformChipEditor(
            values: profile.allergies,
            hint: 'Add an allergy',
            onChanged: (values) => profile.updateProfile(allergies: values),
          ),
          const SizedBox(height: 20),
          Text('Favorite cuisines', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _FreeformChipEditor(
            values: profile.favoriteCuisines,
            hint: 'Add a cuisine',
            onChanged: (values) =>
                profile.updateProfile(favoriteCuisines: values),
          ),
          const SizedBox(height: 20),
          Text('Cooking skill', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: kCookingSkillLevels
                .map((level) => ChoiceChip(
              label: Text(level),
              selected: profile.cookingSkill == level,
              onSelected: (_) =>
                  profile.updateProfile(cookingSkill: level),
            ))
                .toList(),
          ),
          const SizedBox(height: 32),
          const _SectionTitle('App settings'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark mode'),
            value: profile.darkMode,
            onChanged: (value) => profile.setDarkMode(value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifications'),
            value: profile.notificationsEnabled,
            onChanged: (value) => profile.setNotificationsEnabled(value),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Clear recipe history'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await StorageService.instance.clearHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared')),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await AuthService.instance.signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _MultiChipEditor extends StatelessWidget {
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _MultiChipEditor({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (value) {
            final updated = List<String>.from(selected);
            if (value) {
              updated.add(option);
            } else {
              updated.remove(option);
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}

class _FreeformChipEditor extends StatefulWidget {
  final List<String> values;
  final String hint;
  final ValueChanged<List<String>> onChanged;

  const _FreeformChipEditor({
    required this.values,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<_FreeformChipEditor> createState() => _FreeformChipEditorState();
}

class _FreeformChipEditorState extends State<_FreeformChipEditor> {
  final _controller = TextEditingController();

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.values.contains(text)) return;
    widget.onChanged([...widget.values, text]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.values.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.values
                .map((v) => Chip(
              label: Text(v),
              onDeleted: () {
                final updated = List<String>.from(widget.values)
                  ..remove(v);
                widget.onChanged(updated);
              },
            ))
                .toList(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: widget.hint),
                onSubmitted: (_) => _add(),
              ),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: _add),
          ],
        ),
      ],
    );
  }
}
