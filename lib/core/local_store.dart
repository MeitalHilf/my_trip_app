import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import '../models/budget.dart';

class LocalStore {
  static const _kActivities = 'activities';
  static const _kBudget = 'budget';

  // -------- Activities --------
  static Future<List<Activity>> loadActivities() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kActivities);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(Activity.fromJson).toList();
  }

  static Future<void> saveActivities(List<Activity> data) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(data.map((e) => e.toJson()).toList());
    await sp.setString(_kActivities, raw);
  }

  // -------- Budget (categories) --------
  static Future<List<BudgetCategory>> loadBudget() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kBudget);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(BudgetCategory.fromJson).toList();
  }

  static Future<void> saveBudget(List<BudgetCategory> cats) async {
    final sp = await SharedPreferences.getInstance();
    final raw = jsonEncode(cats.map((c) => c.toJson()).toList());
    await sp.setString(_kBudget, raw);
  }
}