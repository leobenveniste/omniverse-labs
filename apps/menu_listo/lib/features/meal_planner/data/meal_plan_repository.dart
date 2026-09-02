import 'package:menu_listo/core/database/app_database.dart';
import '../models/meal_plan_model.dart';
import '../models/meal_plan_template_model.dart';

class MealPlanRepository {
  final AppDatabase _db;

  MealPlanRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;

  Future<List<MealPlanItem>> getMealPlansForWeek(List<String> dateStrings) {
    return _db.getMealPlansForWeek(dateStrings);
  }

  Future<void> setMealPlan(MealPlanItem item) {
    return _db.setMealPlan(item);
  }

  Future<void> deleteMealPlan(String id) {
    return _db.deleteMealPlan(id);
  }

  Future<void> clearMealPlansForWeek(List<String> dateStrings) {
    return _db.clearMealPlansForWeek(dateStrings);
  }

  Future<List<MealPlanTemplate>> getAllTemplates() {
    return _db.getAllMealPlanTemplates();
  }

  Future<void> saveTemplate(MealPlanTemplate template) {
    return _db.saveMealPlanTemplate(template);
  }

  Future<void> deleteTemplate(String id) {
    return _db.deleteMealPlanTemplate(id);
  }
}
