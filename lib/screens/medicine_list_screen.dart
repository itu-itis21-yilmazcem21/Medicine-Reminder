import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/db.dart';
//import '../services/notification_service.dart';
import 'add_edit_medicine_screen.dart';
import 'history_screen.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  late Future<List<Medicine>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadMedicines();
  }

  Future<List<Medicine>> _loadMedicines() => AppDatabase().getMedicines();

  Future<void> _reload() async {
    setState(() {
      _future = _loadMedicines();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('\u0130la\u00E7lar\u0131m')),
      body: FutureBuilder<List<Medicine>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final medicines = snapshot.data!;
          if (medicines.isEmpty) {
            return const Center(
              child: Text(
                'Hen\u00FCz ila\u00E7 eklenmedi. Sa\u011F alttaki "+" d\u00FC\u011Fmesiyle ekleyin.',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) => _MedicineTile(
                medicine: medicines[index],
                onChanged: _reload,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '\u0130la\u00E7 Ekle',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditMedicineScreen()),
          );
          await _reload();
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              tooltip: 'Ge\u00E7mi\u015F / \u0130statistik',
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  _MedicineTile({
    required this.medicine,
    required this.onChanged,
  }) : _dateFormat = DateFormat('d MMM');

  final Medicine medicine;
  final VoidCallback onChanged;
  final DateFormat _dateFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          medicine.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${medicine.dose} \u2022 ${_dateFormat.format(medicine.startDate)} - '
          '${_dateFormat.format(medicine.endDate)}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditMedicineScreen(editing: medicine),
                  ),
                );
                onChanged();
                break;
              case 'delete':
                final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('\u0130lac\u0131 Sil'),
                        content: Text(
                          '"${medicine.name}" silinsin mi? T\u00FCm hat\u0131rlatmalar iptal edilecek.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Vazge\u00E7'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    ) ??
                    false;
                if (!confirm) return;
                await AppDatabase().deleteMedicine(medicine.id!);
                //await NotificationService().cancelAllForMedicine(medicine.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${medicine.name} silindi.')),
                  );
                }
                onChanged();
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('D\u00FCzenle')),
            PopupMenuItem(value: 'delete', child: Text('Sil')),
          ],
        ),
      ),
    );
  }
}
