import 'package:flutter/material.dart';

/// Modelo de datos para un medicamento
class Medication {
  final String id;
  final String name;
  final String? imagePath;
  final TimeOfDay scheduleTime;
  final List<TimeOfDay> times; // Múltiples horarios
  final String frequency;
  final double dose;
  final String doseUnit;
  final int? totalQuantity;
  final DateTime? startDate;
  final DateTime? endDate;
  final String soundType;
  final bool canPostpone;
  final int postponeMinutes;
  final bool isActive;
  final IconData icon;

  /// Obtiene la dosis formateada (ej: "600mg")
  String get dosage => '$dose$doseUnit';

  Medication({
    required this.id,
    required this.name,
    this.imagePath,
    required this.scheduleTime,
    List<TimeOfDay>? times,
    required this.frequency,
    required this.dose,
    required this.doseUnit,
    this.totalQuantity,
    this.startDate,
    this.endDate,
    this.soundType = 'Predeterminado',
    this.canPostpone = true,
    this.postponeMinutes = 15,
    required this.isActive,
    required this.icon,
  }) : times = times ?? [scheduleTime];

  /// Obtiene la próxima hora de toma formateada
  String get nextDoseTime {
    final minute = scheduleTime.minute.toString().padLeft(2, '0');
    final period = scheduleTime.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = scheduleTime.hourOfPeriod == 0
        ? 12
        : scheduleTime.hourOfPeriod;
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Crea una copia del medicamento con algunos campos modificados
  Medication copyWith({
    String? id,
    String? name,
    String? imagePath,
    TimeOfDay? scheduleTime,
    List<TimeOfDay>? times,
    String? frequency,
    double? dose,
    String? doseUnit,
    int? totalQuantity,
    DateTime? startDate,
    DateTime? endDate,
    String? soundType,
    bool? canPostpone,
    int? postponeMinutes,
    bool? isActive,
    IconData? icon,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      times: times ?? this.times,
      frequency: frequency ?? this.frequency,
      dose: dose ?? this.dose,
      doseUnit: doseUnit ?? this.doseUnit,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      soundType: soundType ?? this.soundType,
      canPostpone: canPostpone ?? this.canPostpone,
      postponeMinutes: postponeMinutes ?? this.postponeMinutes,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
    );
  }

  /// Convierte el medicamento a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'scheduleTime': {
        'hour': scheduleTime.hour,
        'minute': scheduleTime.minute,
      },
      'times': times
          .map((time) => {'hour': time.hour, 'minute': time.minute})
          .toList(),
      'frequency': frequency,
      'dose': dose,
      'doseUnit': doseUnit,
      'totalQuantity': totalQuantity,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'soundType': soundType,
      'canPostpone': canPostpone,
      'postponeMinutes': postponeMinutes,
      'isActive': isActive,
      'iconCodePoint': icon.codePoint,
    };
  }

  /// Crea un medicamento desde un Map de Firestore
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      imagePath: map['imagePath'] as String?,
      scheduleTime: TimeOfDay(
        hour: map['scheduleTime']['hour'] as int,
        minute: map['scheduleTime']['minute'] as int,
      ),
      times:
          (map['times'] as List<dynamic>?)
              ?.map(
                (time) => TimeOfDay(
                  hour: time['hour'] as int,
                  minute: time['minute'] as int,
                ),
              )
              .toList() ??
          [],
      frequency: map['frequency'] as String,
      dose: (map['dose'] as num).toDouble(),
      doseUnit: map['doseUnit'] as String,
      totalQuantity: map['totalQuantity'] as int?,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      soundType: map['soundType'] as String? ?? 'Predeterminado',
      canPostpone: map['canPostpone'] as bool? ?? true,
      postponeMinutes: map['postponeMinutes'] as int? ?? 15,
      isActive: map['isActive'] as bool? ?? true,
      icon: IconData(
        map['iconCodePoint'] as int? ?? Icons.medication.codePoint,
        fontFamily: 'MaterialIcons',
      ),
    );
  }
}
