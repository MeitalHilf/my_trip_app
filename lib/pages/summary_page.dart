import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/local_store.dart';
import '../models/budget.dart';
import '../models/activity.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _loading = true;
  List<BudgetCategory> _cats = [];
  List<Activity> _acts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await LocalStore.loadBudget();
    final acts = await LocalStore.loadActivities();

    // debug prints לקונסול – יעזרו לנו לראות מה נטען
    // (Console בתחתית Android Studio)
    // ניתן להשאיר או להסיר אח״כ.
    // ignore: avoid_print
    print('SUMMARY: loaded cats=${cats.length}, acts=${acts.length}');
    for (final c in cats) {
      final m = _asMap(c);
      final name = m['name'] ?? m['title'] ?? '—';
      final ex = _expenseList(m);
      // ignore: avoid_print
      print('  cat "$name": ${ex.length} expenses, total=${_catTotalFromMap(m)}');
    }

    if (!mounted) return;
    setState(() {
      _cats = cats;
      _acts = acts;
      _loading = false;
    });
  }

  // ---------- helpers לגישה דינמית לשדות ----------

  Map<String, dynamic> _asMap(Object o) {
    // ממיר כל אובייקט ל-Map כדי שנוכל לקרוא שדות בצורה גמישה
    return jsonDecode(jsonEncode(o)) as Map<String, dynamic>;
  }

  // מאתר את רשימת ההוצאות בקטגוריה: expenses / items / records
  List<dynamic> _expenseList(Map<String, dynamic> catMap) {
    final v = catMap['expenses'] ?? catMap['items'] ?? catMap['records'];
    if (v is List) return v;
    return const [];
  }

  // מאתר שם קטגוריה: name / title
  String _catName(Map<String, dynamic> catMap) {
    return (catMap['name'] ?? catMap['title'] ?? '').toString();
  }

  // מאתר “מסגרת” תקציב: limit / max / budget (אם אין – 0)
  double _catLimit(Map<String, dynamic> catMap) {
    final v = catMap['limit'] ?? catMap['max'] ?? catMap['budget'];
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  // מאתר סכום בהוצאה: amount / sum / value / price / cost
  double _expenseAmount(dynamic expenseMapLike) {
    if (expenseMapLike is Map) {
      final v = expenseMapLike['amount'] ??
          expenseMapLike['sum'] ??
          expenseMapLike['value'] ??
          expenseMapLike['price'] ??
          expenseMapLike['cost'];
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }
    return 0;
  }

  // סכום הוצאות לקטגוריה (מפה)
  double _catTotalFromMap(Map<String, dynamic> catMap) {
    final ex = _expenseList(catMap);
    double s = 0;
    for (final e in ex) {
      s += _expenseAmount(e);
    }
    return s;
  }

  // ---------- חישובים כלליים ----------

  double get _totalSpent {
    double total = 0;
    for (final c in _cats) {
      total += _catTotalFromMap(_asMap(c));
    }
    return total;
  }

  double get _totalLimit {
    double total = 0;
    for (final c in _cats) {
      total += _catLimit(_asMap(c));
    }
    return total;
  }

  int get _doneCount => _acts.where((a) => a.done == true).length;

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasAnyData = _cats.isNotEmpty || _acts.isNotEmpty;

    return Scaffold(
      body: hasAnyData
          ? ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('סה״כ הוצאות', _money(_totalSpent)),
          const SizedBox(height: 12),
          if (_totalLimit > 0)
            _tile('מסגרת תקציב כוללת', _money(_totalLimit)),
          const SizedBox(height: 12),
          _tile('פעילויות שהושלמו', '$_doneCount מתוך ${_acts.length}'),
          const SizedBox(height: 24),
          Text('הוצאות לפי קטגוריה',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._cats.map((c) {
            final m = _asMap(c);
            final name = _catName(m);
            final catTotal = _catTotalFromMap(m);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              trailing: Text(_money(catTotal)),
            );
          }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('רענון נתונים'),
          ),
        ],
      )
          : const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "אין נתונים עדיין.\nהוסיפי תקציבים והוצאות בלשונית 'תקציב'.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _tile(String title, String value) => Container(
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
