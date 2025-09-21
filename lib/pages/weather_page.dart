import 'package:flutter/material.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _cityCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _weather; // תוצאת דוגמה לפני חיבור API

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('מזג אוויר', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'עיר',
                    hintText: 'לדוגמה: Tel Aviv',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _onSearch,
                    icon: const Icon(Icons.cloud_outlined),
                    label: const Text('בדיקת מזג אוויר'),
                  ),
                ),
                const SizedBox(height: 20),
                if (_loading) const CircularProgressIndicator(),
                if (_error != null)
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                if (_weather != null) _WeatherCard(data: _weather!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSearch() {
    setState(() {
      _loading = true;
      _error = null;
    });

    // TODO: בשלב הבא נחבר ל-API אמיתי (עם הטוקן)
    // כרגע רק מדמה תשובה כדי לראות את ה-UI
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _loading = false;
        _weather = {
          'city': _cityCtrl.text.isEmpty ? 'Example City' : _cityCtrl.text,
          'temp': 22,
          'desc': 'דוגמה בלבד',
        };
      });
    });
  }
}

class _WeatherCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _WeatherCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${data['city']}', style: t.titleLarge),
            const SizedBox(height: 8),
            Text('${data['temp']}°C', style: t.displaySmall),
            const SizedBox(height: 4),
            Text('${data['desc']}', style: t.bodyLarge),
          ],
        ),
      ),
    );
  }
}
