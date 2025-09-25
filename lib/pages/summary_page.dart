import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _loading = true;

  // נתונים מחושבים
  double _totalSpent = 0;
  Map<String, double> _byCategory = {};
  int _doneCount = 0;
  int _activitiesCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();

    // ----- תקציב: קורא מפתח budget_items_v1 (מה-BudgetPage שלך) -----
    final rawBudget = sp.getString('budget_items_v1');
    double total = 0;
    final byCat = <String, double>{};
    if (rawBudget != null && rawBudget.isNotEmpty) {
      try {
        final list = jsonDecode(rawBudget) as List<dynamic>;
        for (final item in list) {
          if (item is Map) {
            final category = (item['category'] ?? 'ללא קטגוריה').toString();
            final amount = _toDouble(item['amount']);
            total += amount;
            byCat.update(category, (v) => v + amount, ifAbsent: () => amount);
          }
        }
      } catch (_) {
        // אם יש פורמט ישן/שגוי – פשוט נשאיר 0
      }
    }

    // ----- פעילויות: קורא מפתח activities_store_v1 (מה-ActivitiesPage שלך) -----
    final rawActs = sp.getString('activities_store_v1');
    int done = 0, all = 0;
    if (rawActs != null && rawActs.isNotEmpty) {
      try {
        final list = jsonDecode(rawActs) as List<dynamic>;
        all = list.length;
        for (final a in list) {
          if (a is Map && (a['done'] == true)) done++;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _totalSpent = total;
      _byCategory = byCat;
      _doneCount = done;
      _activitiesCount = all;
      _loading = false;
    });
  }

  double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tiles = <Widget>[
      _tile(context, 'סה״כ הוצאות', _money(_totalSpent)),
      const SizedBox(height: 12),
      _tile(context, 'פעילויות שהושלמו', '$_doneCount מתוך $_activitiesCount'),
      const SizedBox(height: 24),
      Text('הוצאות לפי קטגוריה', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ..._byCategory.entries.map((e) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(e.key),
        trailing: Text(_money(e.value)),
      )),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('רענון נתונים'),
      ),
    ];

    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(16), children: tiles),
    );
  }

  Widget _tile(BuildContext context, String title, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Row(
      children: [
        Expanded(child: Text(title)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );

  String _money(double v) => '₪${v.toStringAsFixed(2)}';
}
