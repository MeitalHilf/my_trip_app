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
  double _totalSpent = 0;
  double _totalPlanned = 0;
  Map<String, double> _byCategory = {};
  Map<String, double> _planned = {};
  int _doneCount = 0;
  int _activitiesCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();

    // הוצאות
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
      } catch (_) {}
    }

    // מתוכנן לכל קטגוריה
    final rawPlanned = sp.getString('budget_planned_v1');
    final plannedMap = <String, double>{};
    double totalPlanned = 0;
    if (rawPlanned != null && rawPlanned.isNotEmpty) {
      try {
        final m = jsonDecode(rawPlanned) as Map<String, dynamic>;
        m.forEach((k, v) {
          final d = _toDouble(v);
          plannedMap[k] = d;
          totalPlanned += d;
        });
      } catch (_) {}
    }

    // פעילויות
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
      _planned = plannedMap;
      _totalPlanned = totalPlanned;
      _doneCount = done;
      _activitiesCount = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final remaining = _totalPlanned - _totalSpent;
    final cats = _byCategory.keys.toList()..sort();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(context, 'סה״כ הוצאות', _money(_totalSpent)),
          const SizedBox(height: 12),
          _tile(context, 'סה״כ תקציב מתוכנן', _money(_totalPlanned)),
          const SizedBox(height: 12),
          _tile(
            context,
            'יתרה (מתוכנן − הוצאות)',
            _money(remaining),
            color: remaining >= 0 ? Colors.teal : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          _tile(context, 'פעילויות שהושלמו', '$_doneCount מתוך $_activitiesCount'),
          const SizedBox(height: 24),
          Text('פירוט לפי קטגוריה', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...cats.map((cat) {
            final spent = _byCategory[cat] ?? 0;
            final plan = _planned[cat] ?? 0;
            final rem = plan - spent;
            final subtitle = plan > 0
                ? 'מתוכנן: ${_money(plan)} • הוצאות: ${_money(spent)} • יתרה: ${_money(rem)}'
                : 'הוצאות: ${_money(spent)}';
            return Card(
              child: ListTile(
                title: Text(cat),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    color: rem >= 0 ? Colors.teal : Theme.of(context).colorScheme.error,
                  ),
                ),
                trailing: Text(_money(spent)),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('רענון נתונים'),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _money(double v) => '₪${v.toStringAsFixed(2)}';
}
