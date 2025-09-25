import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  WeatherResult? _result;

  @override
  void initState() {
    super.initState();
    // ברירת מחדל: תל אביב (לפי האפיון)
    _cityCtrl.text = 'Tel Aviv';
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final city = _cityCtrl.text.trim();
    if (city.isEmpty) {
      setState(() {
        _error = 'הקלידי שם עיר';
        _result = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final base  = dotenv.env['WEATHER_API_BASE'] ?? 'https://api.openweathermap.org/data/2.5';
      // תומך בשני שמות מפתח אפשריים ב-env (OPENWEATHER_API_KEY או WEATHER_API_KEY)
      final key   = dotenv.env['OPENWEATHER_API_KEY'] ?? dotenv.env['WEATHER_API_KEY'];
      final units = dotenv.env['WEATHER_UNITS'] ?? 'metric';
      final lang  = dotenv.env['WEATHER_LANG'] ?? 'he';

      if (key == null || key.isEmpty) {
        throw Exception('לא נמצא מפתח API בקובץ env');
      }

      final uri = Uri.parse('$base/weather').replace(queryParameters: {
        'q': city,
        'appid': key,
        'units': units,
        'lang': lang,
      });

      final res = await http.get(uri);
      if (res.statusCode != 200) {
        // מנסה לחלץ הודעת שגיאה קריאה
        String msg = 'שגיאת שרת (${res.statusCode})';
        try {
          final body = jsonDecode(res.body);
          if (body is Map && body['message'] != null) {
            msg = '$msg: ${body['message']}';
          }
        } catch (_) {}
        throw Exception(msg);
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _result = WeatherResult.fromOpenWeather(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _result = null;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('מזג אוויר', style: t.headlineSmall),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (_result != null) WeatherCard(result: _result!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherResult {
  final String city;
  final double temp;
  final String description;
  final String iconCode; // לדוגמה: "10d"

  WeatherResult({
    required this.city,
    required this.temp,
    required this.description,
    required this.iconCode,
  });

  // בנאי ייעודי לפורמט של OpenWeather
  factory WeatherResult.fromOpenWeather(Map<String, dynamic> json) {
    final temp = (json['main']?['temp'] as num?)?.toDouble() ?? double.nan;
    final weatherList = (json['weather'] is List) ? (json['weather'] as List) : [];
    final first = (weatherList.isNotEmpty && weatherList.first is Map) ? weatherList.first as Map : {};
    final desc = first['description'] as String? ?? '';
    final icon = first['icon'] as String? ?? '';
    return WeatherResult(
      city: json['name'] as String? ?? '',
      temp: temp,
      description: desc,
      iconCode: icon,
    );
  }

  // URL לאייקון של OpenWeather
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}

class WeatherCard extends StatelessWidget {
  final WeatherResult result;
  const WeatherCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.city, style: t.titleLarge),
            const SizedBox(height: 8),
            // אייקון מזג האוויר
            if (result.iconCode.isNotEmpty)
              Image.network(result.iconUrl, width: 80, height: 80),
            const SizedBox(height: 8),
            Text('${result.temp.round()}°C', style: t.displaySmall),
            const SizedBox(height: 4),
            Text(result.description, style: t.bodyLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
