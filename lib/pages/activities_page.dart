import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';

class ActivitiesPage extends StatefulWidget {
  final List<Activity> activities;
  final void Function(Activity activity) onDelete;
  final void Function(Activity activity) onToggleDone;

  const ActivitiesPage({
    super.key,
    required this.activities,
    required this.onDelete,
    required this.onToggleDone,
  });

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}


class _ActivitiesPageState extends State<ActivitiesPage> {
  static const _storeKey = 'activities_store_v1';
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _pickedDateTime;

  List<Activity> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    _items = raw == null ? [] : Activity.decodeList(raw);
    _sort();
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, Activity.encodeList(_items));
  }

  void _sort() {
    _items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _addActivity() async {
    _titleCtrl.clear();
    _descCtrl.clear();
    _pickedDateTime = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('הוספת פעילות', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'שם הפעילות (חובה)',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'תיאור (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final now = _pickedDateTime ?? DateTime.now();
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: now,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d == null) return;
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(now),
                        );
                        if (t == null) return;
                        _pickedDateTime = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          t.hour,
                          t.minute,
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.event),
                      label: Text(_pickedDateTime == null
                          ? 'תאריך ושעה'
                          : DateFormat('dd/MM/yyyy · HH:mm')
                          .format(_pickedDateTime!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('הוספה'),
                  onPressed: () {
                    if (_titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('נא למלא שם פעילות')),
                      );
                      return;
                    }
                    final when = _pickedDateTime ?? DateTime.now();
                    setState(() {
                      _items.add(Activity(
                        id: UniqueKey().toString(),
                        title: _titleCtrl.text.trim(),
                        description: _descCtrl.text.trim().isEmpty
                            ? null
                            : _descCtrl.text.trim(),
                        dateTime: when,
                      ));
                      _sort();
                    });
                    _save();
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleDone(Activity a, bool value) async {
    setState(() {
      final idx = _items.indexWhere((x) => x.id == a.id);
      if (idx != -1) _items[idx] = a.copyWith(done: value);
    });
    await _save();
  }

  Future<void> _delete(Activity a) async {
    setState(() => _items.removeWhere((x) => x.id == a.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('פעילויות')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addActivity,
        icon: const Icon(Icons.add),
        label: const Text('הוסף'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
        child: Text('אין פעילויות עדיין.\nלחצי על + כדי להוסיף',
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(color: Colors.grey)),
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final a = _items[i];
          final subtitle = [
            DateFormat('dd/MM/yyyy · HH:mm').format(a.dateTime),
            if (a.description?.isNotEmpty == true) a.description!,
          ].join(' · ');

          return Card(
            child: ListTile(
              leading: Checkbox(
                value: a.done,
                onChanged: (v) => _toggleDone(a, v ?? false),
              ),
              title: Text(
                a.title,
                style: a.done
                    ? t.titleMedium?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                )
                    : t.titleMedium,
              ),
              subtitle: Text(subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(a),
                tooltip: 'מחיקה',
              ),
            ),
          );
        },
      ),
    );
  }
}
