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

  const RecipeFilters({
    this.dietary = const {},
    this.maxTotalMinutes,
    this.servings = 2,
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

class GeminiService {
  final String apiKey;
  final String modelName;
  static const _uuid = Uuid();

  GeminiService({required this.apiKey, this.modelName = 'gemini-3.5-flash-lite'});

  /// The strict JSON schema Gemini must follow. Using [Schema] +
  /// `responseMimeType: application/json` guarantees the model returns
  /// parseable JSON that maps directly onto our [Recipe] model, instead
  /// of loose prose we'd have to regex out.
  Schema get _responseSchema => Schema.array(
        description: 'A list of candidate recipes based on detected items.',
        items: Schema.object(
          properties: {
            'title': Schema.string(description: 'Short, appetizing recipe name.'),
            'description': Schema.string(
                description: 'One or two sentence summary of the dish.'),
            'prepTimeMinutes': Schema.integer(),
            'cookTimeMinutes': Schema.integer(),
            'difficulty': Schema.string(
                description: 'One of: easy, medium, hard.'),
            'servings': Schema.integer(),
            'ingredients': Schema.array(
              description: 'Every ingredient needed for the recipe.',
              items: Schema.object(properties: {
                'name': Schema.string(),
                'quantity': Schema.string(
                    description: 'e.g. "2 cups", "1 clove", "to taste"'),
                'isPantryStaple': Schema.boolean(
                    description:
                        'true if this is a common staple (salt, oil, water) rather than something identified in the photo.'),
              }, requiredProperties: [
                'name',
                'quantity',
                'isPantryStaple'
              ]),
            ),
            'missingIngredients': Schema.array(
              description:
                  'Ingredients the recipe needs that were NOT visible in the photo, so the user knows what to buy.',
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
        ),
      );

  GenerativeModel _buildModel() {
    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _responseSchema,
        temperature: 0.6,
      ),
    );
  }

  String _buildPrompt(RecipeFilters filters) {
    return '''
You are a professional chef and nutritionist acting as an AI pantry scanner.

Look carefully at the attached photo of a fridge, pantry, or countertop.
Identify every visible vegetable, protein, sauce, dairy item, and pantry
staple you can confidently recognize.

Using ONLY those detected items (plus common staples like oil, salt,
pepper, and water, which you may assume are available), propose 3
distinct, realistic recipes the user could cook.

For any recipe that would be meaningfully improved by one or two
additional ingredients NOT visible in the photo, list those separately
in "missingIngredients" rather than pretending they were detected.

${filters.toPromptClause()}

Return recipes ordered from most to least recommended given what's
available. Be specific and practical in the steps - a home cook should
be able to follow them without guessing.
''';
  }

  /// Sends the pantry photo (as raw bytes) to Gemini and returns a list
  /// of structured [Recipe] objects.
  Future<List<Recipe>> generateRecipesFromImage({
    required Uint8List imageBytes,
    required String mimeType, // e.g. 'image/jpeg'
    RecipeFilters filters = const RecipeFilters(),
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiPantryException(
          'Missing Gemini API key. Add GEMINI_API_KEY to your .env file.');
    }

    final model = _buildModel();
    final prompt = _buildPrompt(filters);

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ])
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
        throw GeminiPantryException(
            'Unexpected response shape from the model.');
      }

      return decoded
          .map((item) =>
              Recipe.fromJson(Map<String, dynamic>.from(item), id: _uuid.v4()))
          .toList();
    } on GeminiPantryException {
      rethrow;
    } catch (e) {
      throw GeminiPantryException('Could not analyze the photo: $e');
    }
  }
}
