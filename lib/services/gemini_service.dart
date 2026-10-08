import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';

import '../models/recipe.dart';

/// Dietary / preference filters the user can toggle before scanning.
class RecipeFilters {
  final Set<String> dietary; // e.g. {"Vegan", "High-Protein"}
  final int? maxTotalMinutes; // e.g. 20 for "Under 20 mins"
  final int servings;
  final String? cuisine; // e.g. "Filipino", "Italian" - optional

  const RecipeFilters({
    this.dietary = const {},
    this.maxTotalMinutes,
    this.servings = 2,
    this.cuisine,
  });

  String toPromptClause() {
    final parts = <String>[];
    if (dietary.isNotEmpty) {
      parts.add('Dietary requirements: ${dietary.join(", ")}.');
    }
    if (maxTotalMinutes != null) {
      parts.add(
          'Total prep + cook time must be under $maxTotalMinutes minutes.');
    }
    if (cuisine != null && cuisine!.trim().isNotEmpty) {
      parts.add('Preferred cuisine: ${cuisine!.trim()}.');
    }
    parts.add('Scale ingredient quantities for $servings servings.');
    return parts.join(' ');
  }
}

class GeminiPantryException implements Exception {
  final String message;
  GeminiPantryException(this.message);
  @override
  String toString() => message;
}

/// A single turn in the AI Recipe Assistant chat.
class ChatMessage {
  final String role; // 'user' or 'model'
  final String text;
  ChatMessage({required this.role, required this.text});
}

class GeminiService {
  final String apiKey;
  final String modelName;
  static const _uuid = Uuid();

  GeminiService({required this.apiKey, this.modelName = 'gemini-3.1-flash-lite'});

  // ---------------- Recipe schema (shared by image + text generation) ----------------

  Schema get _recipeSchema => Schema.object(
    properties: {
      'title': Schema.string(description: 'Short, appetizing recipe name.'),
      'description':
      Schema.string(description: 'One or two sentence summary of the dish.'),
      'prepTimeMinutes': Schema.integer(),
      'cookTimeMinutes': Schema.integer(),
      'difficulty': Schema.string(description: 'One of: easy, medium, hard.'),
      'servings': Schema.integer(),
      'ingredients': Schema.array(
        description: 'Every ingredient needed for the recipe.',
        items: Schema.object(properties: {
          'name': Schema.string(),
          'quantity': Schema.string(
              description: 'e.g. "2 cups", "1 clove", "to taste"'),
          'isPantryStaple': Schema.boolean(
              description:
              'true if this is a common staple (salt, oil, water) rather than something the user has explicitly.'),
        }, requiredProperties: [
          'name',
          'quantity',
          'isPantryStaple'
        ]),
      ),
      'missingIngredients': Schema.array(
        description:
        'Ingredients the recipe needs that the user does NOT currently have.',
        items: Schema.object(properties: {
          'name': Schema.string(),
          'quantity': Schema.string(),
          'isPantryStaple': Schema.boolean(),
        }, requiredProperties: [
          'name',
          'quantity',
          'isPantryStaple'
        ]),
      ),
      'steps': Schema.array(
        description: 'Ordered, numbered cooking instructions.',
        items: Schema.object(properties: {
          'stepNumber': Schema.integer(),
          'instruction': Schema.string(),
          'durationMinutes': Schema.integer(
              description:
              'Approximate minutes this step takes, if it involves waiting/cooking. Omit if not applicable.',
              nullable: true),
        }, requiredProperties: [
          'stepNumber',
          'instruction'
        ]),
      ),
      'tags': Schema.array(
        description:
        'Labels like "Vegan", "High-Protein", "Under 20 mins", "One-Pot".',
        items: Schema.string(),
      ),
    },
    requiredProperties: [
      'title',
      'description',
      'prepTimeMinutes',
      'cookTimeMinutes',
      'difficulty',
      'servings',
      'ingredients',
      'missingIngredients',
      'steps',
      'tags',
    ],
  );

  Schema get _recipeListSchema => Schema.array(
    description: 'A list of candidate recipes.',
    items: _recipeSchema,
  );

  Schema get _ingredientListSchema => Schema.array(
    description: 'Every distinct ingredient visible in the photo.',
    items: Schema.object(properties: {
      'name': Schema.string(),
      'quantity': Schema.string(
          description:
          'Best-guess quantity/amount visible, e.g. "3", "1 bottle", "half a bunch".'),
      'isPantryStaple': Schema.boolean(),
    }, requiredProperties: [
      'name',
      'quantity',
      'isPantryStaple'
    ]),
  );

  GenerativeModel _jsonModel(Schema schema) {
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
        temperature: 0.6,
      ),
    );
  }

  GenerativeModel _chatModel() {
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(temperature: 0.5),
    );
  }

  void _checkApiKey() {
    if (apiKey.isEmpty) {
      throw GeminiPantryException(
          'Missing Gemini API key. Add GEMINI_API_KEY to your .env file.');
    }
  }

  // ---------------- Step 1: detect ingredients from a photo ----------------

  /// Identifies ingredients visible in the photo without generating full
  /// recipes yet - used for the "confirm/edit detected ingredients" step
  /// before recipe generation.
  Future<List<Ingredient>> detectIngredients({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    _checkApiKey();
    final model = _jsonModel(_ingredientListSchema);

    const prompt = '''
You are a vision system for a pantry-scanning app.

Look carefully at the attached photo of a fridge, pantry, or countertop.
List every distinct vegetable, protein, sauce, dairy item, and pantry
staple you can confidently see. Do not invent items that aren't visible.
Give your best-guess quantity for each.
''';

    final content = [
      Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)])
    ];

    try {
      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiPantryException(
            'The model returned an empty response. Try a clearer photo.');
      }
      final decoded = jsonDecode(text);
      if (decoded is! List) {
        throw GeminiPantryException('Unexpected response shape from the model.');
      }
      return decoded
          .map((item) => Ingredient.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on GeminiPantryException {
      rethrow;
    } catch (e) {
      throw GeminiPantryException('Could not analyze the photo: $e');
    }
  }

  // ---------------- Step 2a: generate recipes from an image directly ----------------

  String _buildImagePrompt(RecipeFilters filters) {
    return '''
You are a professional chef and nutritionist acting as an AI pantry scanner.

Look carefully at the attached photo of a fridge, pantry, or countertop.
Identify every visible vegetable, protein, sauce, dairy item, and pantry
staple you can confidently recognize.

Using ONLY those detected items (plus common staples like oil, salt,
pepper, and water, which you may assume are available), propose 2
distinct, realistic recipes the user could cook. Keep descriptions and
step instructions brief and to the point (1 short sentence per step) -
prioritize speed and clarity over exhaustive detail.

For any recipe that would be meaningfully improved by one or two
additional ingredients NOT visible in the photo, list those separately
in "missingIngredients" rather than pretending they were detected.

${filters.toPromptClause()}

Return recipes ordered from most to least recommended given what's
available. Be specific and practical in the steps - a home cook should
be able to follow them without guessing.
''';
  }

  Future<List<Recipe>> generateRecipesFromImage({
    required Uint8List imageBytes,
    required String mimeType,
    RecipeFilters filters = const RecipeFilters(),
  }) async {
    _checkApiKey();
    final model = _jsonModel(_recipeListSchema);
    final prompt = _buildImagePrompt(filters);

    final content = [
      Content.multi([TextPart(prompt), DataPart(mimeType, imageBytes)])
    ];

    return _runRecipeListRequest(model, content);
  }

  // ---------------- Step 2b: generate recipes from a confirmed ingredient list ----------------

  /// Used after the user has reviewed/edited the AI-detected ingredient
  /// list (the "confirm ingredients" step). No image is re-sent - just
  /// the confirmed list as text, which is faster and cheaper.
  Future<List<Recipe>> generateRecipesFromIngredients({
    required List<Ingredient> ingredients,
    RecipeFilters filters = const RecipeFilters(),
  }) async {
    _checkApiKey();
    final model = _jsonModel(_recipeListSchema);

    final ingredientLines = ingredients
        .map((i) => '- ${i.name} (${i.quantity})')
        .join('\n');

    final prompt = '''
You are a professional chef and nutritionist.

The user has confirmed they have exactly these ingredients available:
$ingredientLines

Using ONLY those ingredients (plus common staples like oil, salt, pepper,
and water, which you may assume are available), propose 2 distinct,
realistic recipes the user could cook. Keep descriptions and step
instructions brief (1 short sentence per step).

For any recipe that would be meaningfully improved by one or two
additional ingredients NOT in the list above, list those separately in
"missingIngredients" rather than pretending the user has them.

${filters.toPromptClause()}

Return recipes ordered from most to least recommended.
''';

    final content = [
      Content.text(prompt),
    ];

    return _runRecipeListRequest(model, content);
  }

  Future<List<Recipe>> _runRecipeListRequest(
      GenerativeModel model, List<Content> content) async {
    try {
      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiPantryException(
            'The model returned an empty response. Please try again.');
      }
      final decoded = jsonDecode(text);
      if (decoded is! List) {
        throw GeminiPantryException('Unexpected response shape from the model.');
      }
      return decoded
          .map((item) =>
          Recipe.fromJson(Map<String, dynamic>.from(item), id: _uuid.v4()))
          .toList();
    } on GeminiPantryException {
      rethrow;
    } catch (e) {
      throw GeminiPantryException('Could not generate recipes: $e');
    }
  }

  // ---------------- AI Recipe Assistant chat ----------------

  /// Answers a follow-up question about a specific recipe (substitutions,
  /// adjustments, clarifying a step, etc.), grounded in that recipe's
  /// full details plus the running chat history.
  Future<String> askAboutRecipe({
    required Recipe recipe,
    required String question,
    List<ChatMessage> history = const [],
  }) async {
    _checkApiKey();
    final model = _chatModel();

    final recipeContext = '''
Recipe: ${recipe.title}
Description: ${recipe.description}
Servings: ${recipe.servings}
Prep time: ${recipe.prepTimeMinutes} min, Cook time: ${recipe.cookTimeMinutes} min
Ingredients: ${recipe.ingredients.map((i) => '${i.name} (${i.quantity})').join(', ')}
Steps:
${recipe.steps.map((s) => '${s.stepNumber}. ${s.instruction}').join('\n')}
''';

    final systemPrimer = '''
You are a friendly, concise cooking assistant helping the user with the
specific recipe below. Answer only using this recipe as context. Keep
answers short and practical (2-4 sentences unless they ask for detail).

$recipeContext
''';

    final content = <Content>[
      Content.text(systemPrimer),
      for (final message in history)
        message.role == 'user'
            ? Content.text(message.text)
            : Content.model([TextPart(message.text)]),
      Content.text(question),
    ];

    try {
      final response = await model.generateContent(content);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw GeminiPantryException('No response - please try again.');
      }
      return text.trim();
    } on GeminiPantryException {
      rethrow;
    } catch (e) {
      throw GeminiPantryException('Could not get a response: $e');
    }
  }
}
