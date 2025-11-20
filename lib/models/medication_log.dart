import 'package:flutter/material.dart';

/// Tipo de acción realizada con el medicamento
enum MedicationAction {
  taken, // Medicamento tomado
  skipped, // Medicamento omitido
  snoozed, // Medicamento pospuesto
}

/// Modelo de datos para el registro de tomas de medicamentos
class MedicationLog {
  final String id;
  final String userId; // ID del paciente que toma el medicamento
  final String medicationId;
  final String medicationName;
  final DateTime scheduledTime; // Hora programada
  final DateTime? actionTime; // Hora en que se realizó la acción
  final MedicationAction action;
  final String? notes; // Notas opcionales

  MedicationLog({
    required this.id,
    required this.userId,
    required this.medicationId,
    required this.medicationName,
    required this.scheduledTime,
    this.actionTime,
    required this.action,
    this.notes,
  });

  /// Verifica si el medicamento fue tomado a tiempo (dentro de 30 minutos)
  bool get wasTakenOnTime {
    if (action != MedicationAction.taken || actionTime == null) {
      return false;
    }
    final difference = actionTime!.difference(scheduledTime).abs();
    return difference.inMinutes <= 30;
  }

  /// Obtiene el día de la semana (0 = Lunes, 6 = Domingo)
  int get weekday {
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    // Convertimos a: 0 = Monday, 6 = Sunday
    return scheduledTime.weekday - 1;
  }

  /// Obtiene el nombre del día de la semana
  String get weekdayName {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return days[weekday];
  }

  /// Crea una copia del log con algunos campos modificados
  MedicationLog copyWith({
    String? id,
    String? userId,
    String? medicationId,
    String? medicationName,
    DateTime? scheduledTime,
    DateTime? actionTime,
    MedicationAction? action,
    String? notes,
  }) {
    return MedicationLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actionTime: actionTime ?? this.actionTime,
      action: action ?? this.action,
      notes: notes ?? this.notes,
    );
  }

  /// Convierte el log a un mapa (para persistencia en Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'actionTime': actionTime?.toIso8601String(),
      'action': action.name, // Usar .name en lugar de .toString()
      'notes': notes,
    };
  }

  /// Crea un log desde un mapa (para persistencia)
  factory MedicationLog.fromMap(Map<String, dynamic> map) {
    return MedicationLog(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      medicationId: map['medicationId'] ?? '',
      medicationName: map['medicationName'] ?? '',
      scheduledTime: DateTime.parse(map['scheduledTime']),
      actionTime: map['actionTime'] != null
          ? DateTime.parse(map['actionTime'])
          : null,
      action: MedicationAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => MedicationAction.taken,
      ),
      notes: map['notes'],
    );
  }

  @override
  String toString() {
    return 'MedicationLog(id: $id, medication: $medicationName, action: $action, scheduled: $scheduledTime)';
  }
}
