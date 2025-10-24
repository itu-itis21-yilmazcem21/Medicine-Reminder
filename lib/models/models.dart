// Basit veri modelleri

class Medicine {
  final int? id;
  final String name;
  final String dose;
  final String? notes;
  final DateTime startDate;
  final DateTime endDate;

  Medicine({
    this.id,
    required this.name,
    required this.dose,
    this.notes,
    required this.startDate,
    required this.endDate,
  });

  Medicine copyWith({
    int? id,
    String? name,
    String? dose,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      Medicine(
        id: id ?? this.id,
        name: name ?? this.name,
        dose: dose ?? this.dose,
        notes: notes ?? this.notes,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'dose': dose,
        'notes': notes,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      };

  static Medicine fromMap(Map<String, dynamic> map) => Medicine(
        id: map['id'] as int?,
        name: map['name'] as String,
        dose: map['dose'] as String,
        notes: map['notes'] as String?,
        startDate: DateTime.parse(map['start_date'] as String),
        endDate: DateTime.parse(map['end_date'] as String),
      );
}

class ScheduleItem {
  final int? id;
  final int medicineId;
  final String timeOfDay; // CSV: HH:mm,HH:mm
  final int daysMask; // Mon=bit0 .. Sun=bit6

  ScheduleItem({
    this.id,
    required this.medicineId,
    required this.timeOfDay,
    required this.daysMask,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicine_id': medicineId,
        'time_of_day': timeOfDay,
        'days_mask': daysMask,
      };

  static ScheduleItem fromMap(Map<String, dynamic> map) => ScheduleItem(
        id: map['id'] as int?,
        medicineId: map['medicine_id'] as int,
        timeOfDay: map['time_of_day'] as String,
        daysMask: map['days_mask'] as int,
      );

  ScheduleItem copyWith({
    int? id,
    int? medicineId,
    String? timeOfDay,
    int? daysMask,
  }) =>
      ScheduleItem(
        id: id ?? this.id,
        medicineId: medicineId ?? this.medicineId,
        timeOfDay: timeOfDay ?? this.timeOfDay,
        daysMask: daysMask ?? this.daysMask,
      );
}

enum IntakeStatus { taken, missed, snoozed }

class IntakeLog {
  final int? id;
  final int medicineId;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final String status; // 'taken' | 'missed' | 'snoozed'

  IntakeLog({
    this.id,
    required this.medicineId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicine_id': medicineId,
        'scheduled_at': scheduledAt.toIso8601String(),
        'taken_at': takenAt?.toIso8601String(),
        'status': status,
      };

  static IntakeLog fromMap(Map<String, dynamic> map) => IntakeLog(
        id: map['id'] as int?,
        medicineId: map['medicine_id'] as int,
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
        takenAt: (map['taken_at'] as String?) != null
            ? DateTime.parse(map['taken_at'] as String)
            : null,
        status: map['status'] as String,
      );
}
