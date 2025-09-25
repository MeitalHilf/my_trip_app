// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'pages/activities_page.dart';
import 'pages/budget_page.dart';
import 'pages/weather_page.dart';
import 'pages/summary_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // טוען את קובץ ה-env (כבר שמנו אותו ב-assets/env ושורת הנכס קיימת ב-pubspec)
  await dotenv.load(fileName: 'assets/env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyTrip',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.purple,
        brightness: Brightness.light,
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

  late final List<Widget> _screens = <Widget>[
    // כאן ActivitiesPage דורשת פרמטרים חובה, נותנים ערכים דיפולטיים כדי שיתקמפל וירוץ
    ActivitiesPage(
      activities: const [],      // רשימה ריקה בינתיים
      onDelete: (_) {},          // callback ריק – נחבר אחר כך
      onToggleDone: (_) {},      // callback ריק – נחבר אחר כך
    ),
    const BudgetPage(),
    const WeatherPage(),
    const SummaryPage(),
  ];

  late final List<String> _titles = <String>[
    'פעילויות',
    'תקציב',
    'מזג אוויר',
    'סיכום',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'פעילויות'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'תקציב'),
          NavigationDestination(icon: Icon(Icons.cloud_outlined), label: 'מזג אוויר'),
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'סיכום'),
        ],
      ),
    );
  }
}
