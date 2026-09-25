import 'package:hive/hive.dart';

part 'recipe.g.dart';

/// A single ingredient line, e.g. "2 cups spinach".
@HiveType(typeId: 0)
class Ingredient extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String quantity;

  @HiveField(2)
  bool isPantryStaple; // true if it's something the user likely already has

  Ingredient({
    required this.name,
    required this.quantity,
    this.isPantryStaple = false,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: (json['name'] ?? '').toString(),
      quantity: (json['quantity'] ?? '').toString(),
      isPantryStaple: json['isPantryStaple'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'isPantryStaple': isPantryStaple,
  };
}

/// A single numbered cooking step.
@HiveType(typeId: 1)
class RecipeStepModel extends HiveObject {
  @HiveField(0)
  int stepNumber;

  @HiveField(1)
  String instruction;

  @HiveField(2)
  int? durationMinutes; // null when the step has no explicit wait/cook time

  RecipeStepModel({
    required this.stepNumber,
    required this.instruction,
    this.durationMinutes,
  });

  factory RecipeStepModel.fromJson(Map<String, dynamic> json) {
    return RecipeStepModel(
      stepNumber: json['stepNumber'] is int
          ? json['stepNumber']
          : int.tryParse('${json['stepNumber']}') ?? 0,
      instruction: (json['instruction'] ?? '').toString(),
      durationMinutes: json['durationMinutes'] == null
          ? null
          : int.tryParse('${json['durationMinutes']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'stepNumber': stepNumber,
    'instruction': instruction,
    'durationMinutes': durationMinutes,
  };
}

@HiveType(typeId: 2)
enum Difficulty {
  @HiveField(0)
  easy,
  @HiveField(1)
  medium,
  @HiveField(2)
  hard,
}

Difficulty difficultyFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'medium':
      return Difficulty.medium;
    case 'hard':
      return Difficulty.hard;
    default:
      return Difficulty.easy;
  }
}

/// The fully structured recipe returned by Gemini and deserialized
/// straight into Flutter widgets.
@HiveType(typeId: 3)
class Recipe extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  int prepTimeMinutes;

  @HiveField(4)
  int cookTimeMinutes;

  @HiveField(5)
  Difficulty difficulty;

  @HiveField(6)
  int servings;

  @HiveField(7)
  List<Ingredient> ingredients;

  @HiveField(8)
  List<Ingredient> missingIngredients; // detected as NOT in the photo

  @HiveField(9)
  List<RecipeStepModel> steps;

  @HiveField(10)
  List<String> tags; // e.g. ["Vegan", "High-Protein", "Under 20 mins"]

  @HiveField(11)
  DateTime savedAt;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.difficulty,
    required this.servings,
    required this.ingredients,
    required this.missingIngredients,
    required this.steps,
    required this.tags,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  factory Recipe.fromJson(Map<String, dynamic> json, {required String id}) {
    return Recipe(
      id: id,
      title: (json['title'] ?? 'Untitled Recipe').toString(),
      description: (json['description'] ?? '').toString(),
      prepTimeMinutes:
      int.tryParse('${json['prepTimeMinutes'] ?? 0}') ?? 0,
      cookTimeMinutes:
      int.tryParse('${json['cookTimeMinutes'] ?? 0}') ?? 0,
      difficulty: difficultyFromString(json['difficulty']?.toString()),
      servings: int.tryParse('${json['servings'] ?? 2}') ?? 2,
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      missingIngredients:
      (json['missingIngredients'] as List<dynamic>? ?? [])
          .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((e) => RecipeStepModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'prepTimeMinutes': prepTimeMinutes,
    'cookTimeMinutes': cookTimeMinutes,
    'difficulty': difficulty.name,
    'servings': servings,
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'missingIngredients':
    missingIngredients.map((e) => e.toJson()).toList(),
    'steps': steps.map((e) => e.toJson()).toList(),
    'tags': tags,
  };
}
