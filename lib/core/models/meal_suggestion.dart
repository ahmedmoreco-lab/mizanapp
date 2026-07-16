import 'mizan_enums.dart';

class MealSuggestion {
  const MealSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.mealType,
    required this.proteinGuidance,
    required this.carbohydrateGuidance,
    required this.vegetableGuidance,
    required this.fatGuidance,
    required this.notes,
  });

  final String id;
  final String title;
  final String description;
  final MealType mealType;
  final String proteinGuidance;
  final String carbohydrateGuidance;
  final String vegetableGuidance;
  final String fatGuidance;
  final String notes;
}
