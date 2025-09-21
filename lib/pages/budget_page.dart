import 'package:flutter/material.dart';
import '../models/budget.dart';

class BudgetPage extends StatelessWidget {
  final List<BudgetCategory> categories;
  final VoidCallback onAddCategory;
  final void Function(String categoryId) onAddExpense;
  final void Function(String categoryId) onDeleteCategory;
  final void Function(String categoryId, String expenseId) onDeleteExpense;

  const BudgetPage({
    super.key,
    required this.categories,
    required this.onAddCategory,
    required this.onAddExpense,
    required this.onDeleteCategory,
    required this.onDeleteExpense,
  });

  double get totalPlanned =>
      categories.fold(0.0, (s, c) => s + c.planned);
  double get totalActual =>
      categories.fold(0.0, (s, c) => s + c.actual);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('סה״כ תקציב מתוכנן: ${_fmt(totalPlanned)} ₪'),
                  Text('סה״כ הוצאות בפועל: ${_fmt(totalActual)} ₪'),
                  const Divider(),
                  Text('פער כולל: ${_fmt(totalPlanned - totalActual)} ₪',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? const Center(
              child: Text('אין קטגוריות. לחץ + להוספה.'),
            )
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final c = categories[i];
                final over = c.actual > c.planned;
                return Card(
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(c.name)),
                        _BudgetStat(label: 'מתוכנן', value: _fmt(c.planned)),
                        const SizedBox(width: 8),
                        _BudgetStat(
                          label: 'בפועל',
                          value: _fmt(c.actual),
                          color: over ? Colors.red : null,
                        ),
                      ],
                    ),
                    childrenPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    children: [
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => onAddExpense(c.id),
                            icon: const Icon(Icons.add),
                            label: const Text('הוסף הוצאה'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => onDeleteCategory(c.id),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('מחק קטגוריה'),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (c.expenses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text('אין הוצאות בקטגוריה זו.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: c.expenses.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                          itemBuilder: (_, j) {
                            final e = c.expenses[j];
                            return Dismissible(
                              key: ValueKey(e.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                color: Colors.red.withOpacity(0.2),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                              ),
                              onDismissed: (_) =>
                                  onDeleteExpense(c.id, e.id),
                              child: ListTile(
                                leading: const Icon(Icons.payment),
                                title: Text(e.title),
                                subtitle: Text(
                                  '${_fmt(e.amount)} ₪  ·  ${_date(e.date)}'
                                      '${e.description != null && e.description!.isNotEmpty ? '\n${e.description}' : ''}',
                                ),
                                isThreeLine: e.description != null &&
                                    e.description!.isNotEmpty,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAddCategory,
        child: const Icon(Icons.add),
        tooltip: 'הוסף קטגוריה',
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(2);
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _BudgetStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text('$value ₪',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}