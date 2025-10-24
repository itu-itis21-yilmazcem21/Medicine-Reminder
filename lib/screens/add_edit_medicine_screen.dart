import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../services/db.dart';
//import '../services/notification_service.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

List<TimeOfDay> _expandTimes(String csv) => csv
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .map((entry) {
      final parts = entry.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();

class AddEditMedicineScreen extends StatefulWidget {
  const AddEditMedicineScreen({super.key, this.editing});

  final Medicine? editing;

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _start = _dateOnly(DateTime.now());
  DateTime _end = _dateOnly(DateTime.now().add(const Duration(days: 30)));
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 9, minute: 0)];
  List<bool> _days =
      List<bool>.filled(7, true); // Pazartesi ba\u015Flang\u0131\u00E7

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _nameCtrl.text = editing.name;
      _doseCtrl.text = editing.dose;
      _notesCtrl.text = editing.notes ?? '';
      _start = editing.startDate;
      _end = editing.endDate;
      AppDatabase().getSchedulesFor(editing.id!).then((items) {
        if (!mounted || items.isEmpty) return;
        final first = items.first;
        setState(() {
          _times
            ..clear()
            ..addAll(_expandTimes(first.timeOfDay));
          _days = _maskToList(first.daysMask);
        });
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int _daysToMask(List<bool> days) {
    var mask = 0;
    for (var i = 0; i < days.length; i++) {
      if (days[i]) {
        mask |= (1 << i);
      }
    }
    return mask;
  }

  List<bool> _maskToList(int mask) =>
      List<bool>.generate(7, (index) => ((mask >> index) & 1) == 1);

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: start ? 'Ba\u015Flang\u0131\u00E7 Tarihi' : 'Biti\u015F Tarihi',
      cancelText: '\u0130ptal',
      confirmText: 'Se\u00E7',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = _dateOnly(picked);
      } else {
        _end = _dateOnly(picked);
      }
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      helpText: 'Saat Se\u00E7',
      cancelText: '\u0130ptal',
      confirmText: 'Se\u00E7',
    );
    if (picked == null) return;
    setState(() {
      _times[index] = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_end.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Biti\u015F tarihi ba\u015Flang\u0131\u00E7tan \u00F6nce olamaz.')),
      );
      return;
    }
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('En az bir hat\u0131rlatma saati ekleyin.')),
      );
      return;
    }
    if (_days.every((selected) => !selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir g\u00FCn se\u00E7melisiniz.')),
      );
      return;
    }

    final medicine = Medicine(
      id: widget.editing?.id,
      name: _nameCtrl.text.trim(),
      dose: _doseCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      startDate: _start,
      endDate: _end,
    );

    final csvTimes = _times.map(_formatTimeOfDay).join(',');
    final schedule = ScheduleItem(
      medicineId: medicine.id ?? 0,
      timeOfDay: csvTimes,
      daysMask: _daysToMask(_days),
    );

    if (widget.editing == null) {
      final id = await AppDatabase().insertMedicine(medicine, [schedule]);
      final saved = Medicine(
        id: id,
        name: medicine.name,
        dose: medicine.dose,
        notes: medicine.notes,
        startDate: medicine.startDate,
        endDate: medicine.endDate,
      );
      //await NotificationService().scheduleAllForMedicine(
      //saved,
    //// [schedule.copyWith(medicineId: id)],
      // );
    } else {
      await AppDatabase().updateMedicine(
        medicine,
        [schedule.copyWith(medicineId: medicine.id!)],
      );
    //await NotificationService().cancelAllForMedicine(medicine.id!);
    //await NotificationService().scheduleAllForMedicine(
    // medicine,
    // [schedule.copyWith(medicineId: medicine.id!)],
    //);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final title = widget.editing == null
        ? '\u0130la\u00E7 Ekle'
        : '\u0130la\u00E7 D\u00FCzenle';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                      labelText: '\u0130la\u00E7 ad\u0131'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Gerekli'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doseCtrl,
                  decoration: const InputDecoration(labelText: 'Doz'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Gerekli'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Not (opsiyonel)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'Ba\u015Flang\u0131\u00E7',
                        value: dateFormat.format(_start),
                        onTap: () => _pickDate(start: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTile(
                        label: 'Biti\u015F',
                        value: dateFormat.format(_end),
                        onTap: () => _pickDate(start: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Hat\u0131rlatma Saatleri',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(_times.length, (index) {
                    final time = _times[index];
                    return Card(
                      child: ListTile(
                        title: Text(_formatTimeOfDay(time)),
                        leading: const Icon(Icons.access_time),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Saati d\u00FCzenle',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _pickTime(index),
                            ),
                            if (_times.length > 1)
                              IconButton(
                                tooltip: 'Sil',
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    _times.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _times.add(const TimeOfDay(hour: 9, minute: 0));
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Saat ekle'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'G\u00FCnler',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    const labels = [
                      'Pzt',
                      'Sal',
                      '\u00C7ar',
                      'Per',
                      'Cum',
                      'Cts',
                      'Paz'
                    ];
                    return FilterChip(
                      label: Text(labels[index]),
                      selected: _days[index],
                      onSelected: (_) {
                        setState(() {
                          _days[index] = !_days[index];
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var i = 0; i < 5; i++) {
                            _days[i] = true;
                          }
                          _days[5] = _days[6] = false;
                        });
                      },
                      child: const Text('Hafta i\u00E7i'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var i = 0; i < 5; i++) {
                            _days[i] = false;
                          }
                          _days[5] = _days[6] = true;
                        });
                      },
                      child: const Text('Hafta sonu'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (var i = 0; i < 7; i++) {
                            _days[i] = true;
                          }
                        });
                      },
                      child: const Text('T\u00FCm\u00FC'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.calendar_today),
        onTap: onTap,
      ),
    );
  }
}
