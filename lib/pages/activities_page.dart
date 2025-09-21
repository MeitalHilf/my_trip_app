import 'package:flutter/material.dart';
import '../models/activity.dart';

class ActivitiesPage extends StatelessWidget {
  final List<Activity> activities;
  final void Function(String id) onToggleDone;
  final void Function(String id) onDelete;

  const ActivitiesPage({
    super.key,
    required this.activities,
    required this.onToggleDone,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const Center(
        child: Text('אין פעילויות עדיין.\nלחץ על + כדי להוסיף', textAlign: TextAlign.center),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = activities[i];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Checkbox(
              value: a.done,
              onChanged: (_) => onToggleDone(a.id),
            ),
            title: Text(
              a.title,
              style: TextStyle(
                decoration: a.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              _fmt(a.dateTime) +
                  (a.description?.isNotEmpty == true ? '\n${a.description}' : ''),
            ),
            isThreeLine: a.description?.isNotEmpty == true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onDelete(a.id),
              tooltip: 'מחק',
            ),
          ),
        );
      },
    );
  }

  String _fmt(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${dt.year}  $hh:$min';
  }
}
