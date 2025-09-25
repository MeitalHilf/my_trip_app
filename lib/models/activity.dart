import 'dart:convert';

class Activity {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool done;

  Activity({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.done = false,
  });

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    bool? done,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      done: done ?? this.done,
    );
  }

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    dateTime: DateTime.parse(json['dateTime'] as String),
    done: json['done'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'done': done,
  };

  static String encodeList(List<Activity> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<Activity> decodeList(String source) =>
      (jsonDecode(source) as List<dynamic>)
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList();
}
