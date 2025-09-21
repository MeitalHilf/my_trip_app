class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String? description;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'date': date.toIso8601String(),
    'description': description,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    title: j['title'] as String,
    amount: (j['amount'] as num).toDouble(),
    date: DateTime.parse(j['date'] as String),
    description: j['description'] as String?,
  );
}

class BudgetCategory {
  final String id;
  final String name;
  final double planned;
  final List<Expense> expenses;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.planned,
    List<Expense>? expenses,
  }) : expenses = expenses ?? [];

  double get actual =>
      expenses.fold(0.0, (s, e) => s + e.amount);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'planned': planned,
    'expenses': expenses.map((e) => e.toJson()).toList(),
  };

  factory BudgetCategory.fromJson(Map<String, dynamic> j) => BudgetCategory(
    id: j['id'] as String,
    name: j['name'] as String,
    planned: (j['planned'] as num).toDouble(),
    expenses: (j['expenses'] as List<dynamic>? ?? [])
        .map((x) => Expense.fromJson(x as Map<String, dynamic>))
        .toList(),
  );
}