import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  static const _storeKey = 'budget_items_v1';

  final List<ExpenseItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null && raw.isNotEmpty) {
      final list = (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(ExpenseItem.fromJson)
          .toList();
      setState(() {
        _items
          ..clear()
          ..addAll(list);
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storeKey, raw);
  }

  double get _total =>
      _items.fold(0.0, (sum, e) => sum + (e.amount ?? 0));

  Future<void> _addItemDialog() async {
    final formKey = GlobalKey<FormState>();
    final noteCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = _categories.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('הוספת הוצאה', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'קטגוריה',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  ))
                      .toList(),
                  onChanged: (v) => category = v ?? _categories.first,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'סכום (₪)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'שדה חובה';
                    final x = double.tryParse(v.replaceAll(',', '.'));
                    if (x == null || x <= 0) return 'סכום לא תקין';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'הערה (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('הוספה'),
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      final amt = double.parse(
                          amountCtrl.text.replaceAll(',', '.'));
                      final item = ExpenseItem(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        category: category,
                        amount: amt,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                        date: DateTime.now(),
                      );
                      setState(() {
                        _items.insert(0, item);
                      });
                      _saveItems();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteItem(ExpenseItem item) {
    setState(() {
      _items.removeWhere((e) => e.id == item.id);
    });
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // סיכום עליון
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('סה״כ הוצאות',
                      style: t.titleMedium),
                ),
                Text('₪${_total.toStringAsFixed(2)}',
                    style: t.headlineSmall),
              ],
            ),
          ),
          const Divider(height: 1),
          // רשימת הוצאות
          Expanded(
            child: _items.isEmpty
                ? Center(
              child: Text('אין הוצאות עדיין',
                  style: t.bodyLarge),
            )
                : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final e = _items[i];
                return Dismissible(
                  key: ValueKey(e.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteItem(e),
                  child: ListTile(
                    title: Text('${e.category} • ₪${(e.amount ?? 0).toStringAsFixed(2)}'),
                    subtitle: Text(
                      [
                        if (e.note != null) e.note!,
                        _formatDate(e.date),
                      ].join(' • '),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItemDialog,
        icon: const Icon(Icons.add),
        label: const Text('הוצאה'),
      ),
    );
  }

  static const _categories = <String>[
    'טיסות',
    'לינה',
    'אוכל',
    'תחבורה',
    'אטרקציות',
    'אחר',
  ];

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day.$m.$y';
  }
}

class ExpenseItem {
  final String id;
  final String category;
  final double? amount;
  final String? note;
  final DateTime? date;

  ExpenseItem({
    required this.id,
    required this.category,
    required this.amount,
    this.note,
    this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'note': note,
    'date': date?.toIso8601String(),
  };

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
    id: json['id'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num?)?.toDouble(),
    note: json['note'] as String?,
    date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
  );
}
