import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/db.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, int>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await AppDatabase().statsLast7Days();
    if (!mounted) return;
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('Ge\u00E7mi\u015F / \u0130statistik')),
      body: stats == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Son 7 G\u00FCn',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      _StatCard(title: 'Ald\u0131m', icon: Icons.check_circle),
                      _StatCard(
                          title: 'Ka\u00E7\u0131rd\u0131m', icon: Icons.cancel),
                      _StatCard(title: 'Ertele', icon: Icons.snooze),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            '${stats['taken'] ?? 0}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${stats['missed'] ?? 0}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${stats['snoozed'] ?? 0}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Expanded(child: _LogsList()),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 6),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogsList extends StatefulWidget {
  const _LogsList();

  @override
  State<_LogsList> createState() => _LogsListState();
}

class _LogsListState extends State<_LogsList> {
  List<Map<String, Object?>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = await AppDatabase().db;
    final rows = await db.rawQuery(
      '''
      SELECT l.*, m.name 
      FROM intake_log l
      JOIN medicine m ON m.id = l.medicine_id
      WHERE l.scheduled_at >= ?
      ORDER BY l.scheduled_at DESC
      ''',
      [DateTime.now().subtract(const Duration(days: 7)).toIso8601String()],
    );
    if (!mounted) return;
    setState(() {
      _rows = rows;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) {
      return const Center(child: Text('Kay\u0131t bulunamad\u0131.'));
    }
    final formatter = DateFormat('dd.MM HH:mm');
    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final scheduled = DateTime.parse(row['scheduled_at'] as String);
        final takenAtRaw = row['taken_at'] as String?;
        final takenAt = takenAtRaw != null ? DateTime.parse(takenAtRaw) : null;
        final status = _localizeStatus(row['status'] as String);
        final subtitle = [
          'Planlanan: ${formatter.format(scheduled)}',
          if (takenAt != null) 'Al\u0131nan: ${formatter.format(takenAt)}',
        ].join(' \u2022 ');
        return ListTile(
          title: Text(row['name'] as String),
          subtitle: Text(subtitle),
          trailing: Text(status),
        );
      },
    );
  }

  String _localizeStatus(String status) {
    switch (status) {
      case 'taken':
        return 'Al\u0131nd\u0131';
      case 'snoozed':
        return 'Ertele';
      case 'missed':
        return 'Ka\u00E7\u0131r\u0131ld\u0131';
      default:
        return status;
    }
  }
}
