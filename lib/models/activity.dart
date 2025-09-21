class Activity {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final bool done;

  Activity({
    required this.id,
    required this.title,
    required this.dateTime,
    this.description,
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

  // JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dateTime': dateTime.toIso8601String(),
    'done': done,
  };

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    dateTime: DateTime.parse(j['dateTime'] as String),
    done: j['done'] as bool? ?? false,
  );
}