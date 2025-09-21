import 'package:flutter/material.dart';
import 'pages/activities_page.dart';
import 'pages/budget_page.dart';
import 'pages/weather_page.dart';
import 'pages/summary_page.dart';
import 'models/activity.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyTrip',
      // RTL לכל האפליקציה
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

  final List<Activity> _activities = [];

  static const _titles = ['פעילויות', 'תקציב', 'מזג אוויר', 'סיכום'];

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ActivitiesPage(
        activities: _activities,
        onToggleDone: _toggleActivityDone,
        onDelete: _deleteActivity,
      ),
      const BudgetPage(),
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

  // כפתור + לטאב "פעילויות"
  Widget? _fabForTab(int index) {
    if (index == 0) {
      return FloatingActionButton(
        onPressed: _openAddActivitySheet, // ← שינוי כאן
        child: const Icon(Icons.add),
        tooltip: 'הוסף פעילות',
      );
    }
    return null;
  }

  // --- פעולות על פעילויות ---

  void _toggleActivityDone(String id) {
    final idx = _activities.indexWhere((a) => a.id == id);
    if (idx == -1) return;
    setState(() {
      final a = _activities[idx];
      _activities[idx] = a.copyWith(done: !a.done);
    });
  }

  void _deleteActivity(String id) {
    setState(() {
      _activities.removeWhere((a) => a.id == id);
    });
  }

  Future<void> _openAddActivitySheet() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    // נפתח Bottom Sheet שמחזיר Activity או null
    final Activity? result = await showModalBottomSheet<Activity>(
      context: context,
      isScrollControlled: true, // כדי שהמקלדת לא תסתיר
      builder: (ctx) {
        // מאפשר סטייט פנימי פשוט ל־sheet (לכפתור "הוסף" יהיה enabled/disabled)
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
                    textInputAction: TextInputAction.done,
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
                              context: ctx,
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
                              context: ctx,
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
                          final activity = Activity(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            dateTime: dt,
                          );
                          Navigator.of(ctx).pop(activity);
                        }
                            : null, // כפתור כבוי אם הטופס לא מלא
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

    // אחרי שה־sheet נסגר, מעדכנים state
    if (!mounted) return;
    if (result != null) {
      setState(() => _activities.add(result));
    }

    titleCtrl.dispose();
    descCtrl.dispose();
  }
}
