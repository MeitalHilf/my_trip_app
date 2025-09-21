import 'package:flutter/material.dart';
import 'pages/activities_page.dart';
import 'pages/budget_page.dart';
import 'pages/weather_page.dart';
import 'pages/summary_page.dart';
import 'models/activity.dart';
import 'models/budget.dart';
import 'core/local_store.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyTrip',
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({super.key});
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _index = 0;

  List<Activity> _activities = [];
  List<BudgetCategory> _categories = [];

  static const _titles = ['פעילויות', 'תקציב', 'מזג אוויר', 'סיכום'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final acts = await LocalStore.loadActivities();
    final cats = await LocalStore.loadBudget();
    setState(() {
      _activities = acts;
      _categories = cats;
    });
  }

  Future<void> _saveActivities() => LocalStore.saveActivities(_activities);
  Future<void> _saveBudget() => LocalStore.saveBudget(_categories);

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ActivitiesPage(
        activities: _activities,
        onToggleDone: _toggleActivityDone,
        onDelete: _deleteActivity,
      ),
      BudgetPage(
        categories: _categories,
        onAddCategory: _openAddCategorySheet,
        onAddExpense: _openAddExpenseSheet,
        onDeleteCategory: _deleteCategory,
        onDeleteExpense: _deleteExpense,
      ),
      const WeatherPage(),
      const SummaryPage(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index]), centerTitle: true),
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'פעילויות'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'תקציב'),
          NavigationDestination(icon: Icon(Icons.cloud), label: 'מזג אוויר'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'סיכום'),
        ],
      ),
      floatingActionButton: _fabForTab(_index),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // -------- FAB --------
  Widget? _fabForTab(int index) {
    if (index == 0) {
      return FloatingActionButton(
        onPressed: _openAddActivitySheet,
        child: const Icon(Icons.add),
        tooltip: 'הוסף פעילות',
      );
    }
    return null;
  }

  // -------- Activities logic --------
  void _toggleActivityDone(String id) {
    final idx = _activities.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    setState(() {
      final a = _activities[idx];
      _activities[idx] = a.copyWith(done: !a.done);
    });
    _saveActivities();
  }

  void _deleteActivity(String id) {
    setState(() => _activities.removeWhere((a) => a.id == id));
    _saveActivities();
  }

  Future<void> _openAddActivitySheet() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    final Activity? result = await showModalBottomSheet<Activity>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final valid = titleCtrl.text.trim().isNotEmpty &&
                pickedDate != null &&
                pickedTime != null;

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('הוספת פעילות',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'שם פעילות *'),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'תיאור (לא חובה)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final now = DateTime.now();
                            final d = await showDatePicker(
                              context: context, // ← חשוב: context של המסך, לא ctx
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 3),
                              initialDate: now,
                            );
                            if (d != null) {
                              pickedDate = d;
                              setSheetState(() {});
                            }
                          },
                          child: Text(
                            pickedDate == null
                                ? 'תאריך'
                                : '${pickedDate!.day.toString().padLeft(2, '0')}/'
                                '${pickedDate!.month.toString().padLeft(2, '0')}/'
                                '${pickedDate!.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context, // ← גם כאן
                              initialTime: TimeOfDay.now(),
                            );
                            if (t != null) {
                              pickedTime = t;
                              setSheetState(() {});
                            }
                          },
                          child: Text(
                            pickedTime == null
                                ? 'שעה'
                                : '${pickedTime!.hour.toString().padLeft(2, '0')}:'
                                '${pickedTime!.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('ביטול'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: valid
                            ? () {
                          final dt = DateTime(
                            pickedDate!.year,
                            pickedDate!.month,
                            pickedDate!.day,
                            pickedTime!.hour,
                            pickedTime!.minute,
                          );
                          final a = Activity(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            dateTime: dt,
                          );
                          Navigator.of(ctx).pop(a);
                        }
                            : null,
                        child: const Text('הוסף'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      setState(() => _activities.add(result));
      _saveActivities();
    }
    titleCtrl.dispose();
    descCtrl.dispose();
  }

  // -------- Budget logic --------
  Future<void> _openAddCategorySheet() async {
    final nameCtrl = TextEditingController();
    final plannedCtrl = TextEditingController();

    final BudgetCategory? cat = await showModalBottomSheet<BudgetCategory>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final planned = double.tryParse(plannedCtrl.text.trim());
            final valid = nameCtrl.text.trim().isNotEmpty &&
                planned != null &&
                planned > 0;

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('הוספת קטגוריה',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'שם קטגוריה *'),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: plannedCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: 'תקציב מתוכנן (₪) *'),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('ביטול'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: valid
                            ? () => Navigator.of(ctx).pop(BudgetCategory(
                          id: DateTime.now()
                              .microsecondsSinceEpoch
                              .toString(),
                          name: nameCtrl.text.trim(),
                          planned: planned!,
                        ))
                            : null,
                        child: const Text('הוסף'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (cat != null) {
      setState(() => _categories.add(cat));
      _saveBudget();
    }
    nameCtrl.dispose();
    plannedCtrl.dispose();
  }

  Future<void> _openAddExpenseSheet(String categoryId) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? pickedDate;

    final Expense? e = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final amount = double.tryParse(amountCtrl.text.trim());
            final valid = titleCtrl.text.trim().isNotEmpty &&
                amount != null &&
                amount > 0 &&
                pickedDate != null;

            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('הוספת הוצאה',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'שם הוצאה *'),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'סכום (₪) *'),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'תיאור (לא חובה)'),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final d = await showDatePicker(
                          context: context, // ← לא ctx
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 3),
                          initialDate: now,
                        );
                        if (d != null) {
                          pickedDate = d;
                          setSheetState(() {});
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        pickedDate == null ? 'בחר תאריך *' : _date(pickedDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        child: const Text('ביטול'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: valid
                            ? () => Navigator.of(ctx).pop(Expense(
                          id: DateTime.now()
                              .microsecondsSinceEpoch
                              .toString(),
                          title: titleCtrl.text.trim(),
                          amount: amount!,
                          date: pickedDate!,
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                        ))
                            : null,
                        child: const Text('הוסף'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (e != null) {
      setState(() {
        final idx = _categories.indexWhere((c) => c.id == categoryId);
        if (idx != -1) _categories[idx].expenses.add(e);
      });
      _saveBudget();
    }
    titleCtrl.dispose();
    amountCtrl.dispose();
    descCtrl.dispose();
  }

  void _deleteCategory(String categoryId) {
    setState(() => _categories.removeWhere((c) => c.id == categoryId));
    _saveBudget();
  }

  void _deleteExpense(String categoryId, String expenseId) {
    setState(() {
      final idx = _categories.indexWhere((c) => c.id == categoryId);
      if (idx != -1) {
        _categories[idx].expenses.removeWhere((e) => e.id == expenseId);
      }
    });
    _saveBudget();
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}