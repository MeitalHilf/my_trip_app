import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  static const _storeKey = 'budget_items_v1';

  final List<BudgetExpenseItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .whereType<Map<String, dynamic>>()
            .map(BudgetExpenseItem.fromJson)
            .toList();
        _items.addAll(list);
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(_storeKey, raw);
  }

  double get _total => _items.fold(0.0, (s, e) => s + (e.amount ?? 0));

  Map<String, List<BudgetExpenseItem>> get _byCategory {
    final map = <String, List<BudgetExpenseItem>>{};
    for (final e in _items) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    // סדר קטגוריות לפי שם
    final sorted = Map.fromEntries(
      map.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  Future<void> _addOrEditDialog({BudgetExpenseItem? existing}) async {
    final formKey = GlobalKey<FormState>();
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    final amountCtrl =
    TextEditingController(text: existing?.amount?.toString() ?? '');
    final categories = const [
      'טיסות',
      'לינה',
      'אוכל',
      'תחבורה',
      'אטרקציות',
      'אחר',
    ];
    String category = existing?.category ?? categories.first;
    DateTime when = existing?.date ?? DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  existing == null ? 'הוספת הוצאה' : 'עריכת הוצאה',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                // קטגוריה
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'קטגוריה',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => category = v ?? categories.first,
                ),
                const SizedBox(height: 12),

                // סכום
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

                // הערה
                TextFormField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'הערה (אופציונלי)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // תאריך
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event),
                        label: Text(DateFormat('dd/MM/yyyy').format(when)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: when,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) {
                            when = DateTime(d.year, d.month, d.day, when.hour, when.minute);
                            // ignore: use_build_context_synchronously
                            (ctx as Element).markNeedsBuild();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // שמירה
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: Icon(existing == null ? Icons.add : Icons.check),
                    label: Text(existing == null ? 'הוספה' : 'שמירה'),
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      final amt =
                      double.parse(amountCtrl.text.replaceAll(',', '.'));

                      if (existing == null) {
                        final item = BudgetExpenseItem(
                          id: DateTime.now()
                              .microsecondsSinceEpoch
                              .toString(),
                          category: category,
                          amount: amt,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                          date: when,
                        );
                        setState(() => _items.insert(0, item));
                      } else {
                        final idx =
                        _items.indexWhere((e) => e.id == existing.id);
                        if (idx != -1) {
                          _items[idx] = existing.copyWith(
                            category: category,
                            amount: amt,
                            note: noteCtrl.text.trim().isEmpty
                                ? null
                                : noteCtrl.text.trim(),
                            date: when,
                          );
                          setState(() {});
                        }
                      }

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

  Future<void> _confirmDelete(BudgetExpenseItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('מחיקת הוצאה'),
        content: const Text('למחוק את ההוצאה הזו?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('בטל')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('מחק')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _items.removeWhere((e) => e.id == item.id));
      _saveItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
        children: [
          // סיכום עליון
          Row(
            children: [
              Expanded(child: Text('סה״כ הוצאות', style: t.titleMedium)),
              Text('₪${_total.toStringAsFixed(2)}', style: t.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),

          // קיבוץ לפי קטגוריה
          ..._byCategory.entries.map((entry) {
            final cat = entry.key;
            final list = entry.value;
            final catTotal =
            list.fold<double>(0, (s, e) => s + (e.amount ?? 0));

            return Card(
              child: ExpansionTile(
                title: Text(cat),
                trailing: Text('₪${catTotal.toStringAsFixed(2)}'),
                children: list.map((e) {
                  final subtitle = [
                    if (e.note?.isNotEmpty == true) e.note!,
                    if (e.date != null)
                      DateFormat('dd/MM/yyyy').format(e.date!),
                  ].join(' • ');

                  return ListTile(
                    title: Text('₪${(e.amount ?? 0).toStringAsFixed(2)}'),
                    subtitle: Text(subtitle),
                    leading: const Icon(Icons.receipt_long),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'עריכה',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _addOrEditDialog(existing: e),
                        ),
                        IconButton(
                          tooltip: 'מחיקה',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(e),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('הוצאה'),
      ),
    );
  }
}

// מודל פשוט ושקוף לשמירה ב-SharedPreferences תחת budget_items_v1
class BudgetExpenseItem {
  final String id;
  final String category;
  final double? amount;
  final String? note;
  final DateTime? date;

  BudgetExpenseItem({
    required this.id,
    required this.category,
    required this.amount,
    this.note,
    this.date,
  });

  BudgetExpenseItem copyWith({
    String? id,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
  }) {
    return BudgetExpenseItem(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'amount': amount,
    'note': note,
    'date': date?.toIso8601String(),
  };

  factory BudgetExpenseItem.fromJson(Map<String, dynamic> json) =>
      BudgetExpenseItem(
        id: json['id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num?)?.toDouble(),
        note: json['note'] as String?,
        date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      );
}
