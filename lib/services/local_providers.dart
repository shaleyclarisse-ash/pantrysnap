import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/pantry_models.dart';
import '../models/recipe.dart';
import 'storage_service.dart';

const _uuid = Uuid();

const List<String> kPantryCategories = [
  'Produce',
  'Protein',
  'Dairy',
  'Grains',
  'Pantry Staple',
  'Other',
];

/// My Pantry - the user's manually-tracked ingredient inventory, plus
/// expiration tracking ("Use Ingredients Soon").
class PantryInventoryProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  List<PantryItem> items = [];

  PantryInventoryProvider() {
    refresh();
  }

  void refresh() {
    items = _storage.getPantryItems();
    notifyListeners();
  }

  Future<void> addItem({
    required String name,
    required String quantity,
    String category = 'Other',
    DateTime? expiryDate,
  }) async {
    final item = PantryItem(
      id: _uuid.v4(),
      name: name,
      quantity: quantity,
      category: category,
      expiryDate: expiryDate,
    );
    await _storage.savePantryItem(item);
    refresh();
  }

  Future<void> updateItem(PantryItem item) async {
    await _storage.savePantryItem(item);
    refresh();
  }

  Future<void> removeItem(String id) async {
    await _storage.removePantryItem(id);
    refresh();
  }

  List<PantryItem> get expiringSoon =>
      items.where((i) => i.isExpiringSoon && !i.isExpired).toList();

  List<PantryItem> get expired => items.where((i) => i.isExpired).toList();
}

/// Shopping List - manual items plus anything pulled in from a recipe's
/// missingIngredients.
class ShoppingListProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  List<ShoppingItem> items = [];

  ShoppingListProvider() {
    refresh();
  }

  void refresh() {
    items = _storage.getShoppingItems();
    notifyListeners();
  }

  Future<void> addItem(String name, String quantity,
      {String? sourceRecipeTitle}) async {
    final item = ShoppingItem(
      id: _uuid.v4(),
      name: name,
      quantity: quantity,
      sourceRecipeTitle: sourceRecipeTitle,
    );
    await _storage.saveShoppingItem(item);
    refresh();
  }

  /// Adds every missing ingredient from a recipe in one go (the
  /// "Add Missing Ingredients" button on a recipe's detail screen).
  Future<void> addFromRecipe(Recipe recipe) async {
    for (final ingredient in recipe.missingIngredients) {
      await _storage.saveShoppingItem(ShoppingItem(
        id: _uuid.v4(),
        name: ingredient.name,
        quantity: ingredient.quantity,
        sourceRecipeTitle: recipe.title,
      ));
    }
    refresh();
  }

  Future<void> toggleChecked(ShoppingItem item) async {
    item.checked = !item.checked;
    await _storage.saveShoppingItem(item);
    refresh();
  }

  Future<void> removeItem(String id) async {
    await _storage.removeShoppingItem(id);
    refresh();
  }

  Future<void> clearChecked() async {
    await _storage.clearCheckedShoppingItems();
    refresh();
  }

  int get uncheckedCount => items.where((i) => !i.checked).length;
}

const List<String> kMealTypes = ['Breakfast', 'Lunch', 'Dinner'];
const List<String> kDaysOfWeek = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Weekly Meal Planner.
class MealPlanProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  List<MealPlanEntry> entries = [];

  MealPlanProvider() {
    refresh();
  }

  void refresh() {
    entries = _storage.getMealPlan();
    notifyListeners();
  }

  List<MealPlanEntry> forDay(int dayOfWeek) =>
      entries.where((e) => e.dayOfWeek == dayOfWeek).toList();

  Future<void> assignRecipe({
    required int dayOfWeek,
    required String mealType,
    required Recipe recipe,
  }) async {
    // Replace any existing entry for this day+meal slot.
    final existing = entries
        .where((e) => e.dayOfWeek == dayOfWeek && e.mealType == mealType)
        .toList();
    for (final e in existing) {
      await _storage.removeMealPlanEntry(e.id);
    }
    await _storage.saveMealPlanEntry(MealPlanEntry(
      id: _uuid.v4(),
      dayOfWeek: dayOfWeek,
      mealType: mealType,
      recipe: recipe,
    ));
    refresh();
  }

  Future<void> removeEntry(String id) async {
    await _storage.removeMealPlanEntry(id);
    refresh();
  }

  /// Collects every ingredient across the whole week's plan that isn't a
  /// pantry staple, for a one-tap "shopping list from meal plan".
  List<Ingredient> collectWeeklyIngredients() {
    final seen = <String>{};
    final result = <Ingredient>[];
    for (final entry in entries) {
      for (final ingredient in entry.recipe.ingredients) {
        final key = ingredient.name.toLowerCase();
        if (!ingredient.isPantryStaple && !seen.contains(key)) {
          seen.add(key);
          result.add(ingredient);
        }
      }
    }
    return result;
  }
}

const List<String> kCookingSkillLevels = ['Beginner', 'Intermediate', 'Advanced'];

/// Profile + Settings, backed by a simple key/value Hive box. Also feeds
/// the user's dietary/allergy/cuisine preferences into the Gemini prompt.
class ProfileProvider extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  static const _kName = 'profile_name';
  static const _kDietary = 'profile_dietary';
  static const _kAllergies = 'profile_allergies';
  static const _kFavoriteCuisines = 'profile_cuisines';
  static const _kCookingSkill = 'profile_skill';
  static const _kDarkMode = 'settings_dark_mode';
  static const _kNotifications = 'settings_notifications';

  String name = '';
  List<String> dietaryPreferences = [];
  List<String> allergies = [];
  List<String> favoriteCuisines = [];
  String cookingSkill = 'Beginner';
  bool darkMode = false;
  bool notificationsEnabled = true;

  ProfileProvider() {
    _load();
  }

  void _load() {
    name = _storage.getSetting<String>(_kName, defaultValue: '') ?? '';
    dietaryPreferences =
        (_storage.getSetting<List>(_kDietary, defaultValue: <String>[]))
            ?.cast<String>() ??
            [];
    allergies =
        (_storage.getSetting<List>(_kAllergies, defaultValue: <String>[]))
            ?.cast<String>() ??
            [];
    favoriteCuisines = (_storage
        .getSetting<List>(_kFavoriteCuisines, defaultValue: <String>[]))
        ?.cast<String>() ??
        [];
    cookingSkill =
        _storage.getSetting<String>(_kCookingSkill, defaultValue: 'Beginner') ??
            'Beginner';
    darkMode = _storage.getSetting<bool>(_kDarkMode, defaultValue: false) ?? false;
    notificationsEnabled =
        _storage.getSetting<bool>(_kNotifications, defaultValue: true) ?? true;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    List<String>? favoriteCuisines,
    String? cookingSkill,
  }) async {
    if (name != null) {
      this.name = name;
      await _storage.setSetting(_kName, name);
    }
    if (dietaryPreferences != null) {
      this.dietaryPreferences = dietaryPreferences;
      await _storage.setSetting(_kDietary, dietaryPreferences);
    }
    if (allergies != null) {
      this.allergies = allergies;
      await _storage.setSetting(_kAllergies, allergies);
    }
    if (favoriteCuisines != null) {
      this.favoriteCuisines = favoriteCuisines;
      await _storage.setSetting(_kFavoriteCuisines, favoriteCuisines);
    }
    if (cookingSkill != null) {
      this.cookingSkill = cookingSkill;
      await _storage.setSetting(_kCookingSkill, cookingSkill);
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _storage.setSetting(_kDarkMode, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    notificationsEnabled = value;
    await _storage.setSetting(_kNotifications, value);
    notifyListeners();
  }
}
