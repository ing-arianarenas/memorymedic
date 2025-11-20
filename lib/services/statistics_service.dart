import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';

/// Período de tiempo para las estadísticas
enum StatisticsPeriod { week, month, year }

/// Datos de adherencia por día
class DailyAdherence {
  final int weekday; // 0 = Lunes, 6 = Domingo
  final double percentage;
  final int taken;
  final int total;

  DailyAdherence({
    required this.weekday,
    required this.percentage,
    required this.taken,
    required this.total,
  });

  String get weekdayName {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return days[weekday];
  }
}

/// Datos de adherencia por medicamento
class MedicationAdherence {
  final String medicationId;
  final String medicationName;
  final double percentage;
  final int taken;
  final int total;
  final int timesPerDay;

  MedicationAdherence({
    required this.medicationId,
    required this.medicationName,
    required this.percentage,
    required this.taken,
    required this.total,
    required this.timesPerDay,
  });
}

/// Servicio para calcular estadísticas de adherencia
class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  // Lista de logs de medicamentos (en producción, esto vendría de una base de datos)
  final List<MedicationLog> _logs = [];

  /// Obtiene todos los logs
  List<MedicationLog> get logs => List.unmodifiable(_logs);

  /// Agrega un nuevo log
  void addLog(MedicationLog log) {
    _logs.add(log);
    debugPrint('Log agregado: ${log.medicationName} - ${log.action}');
  }

  /// Elimina logs de un medicamento específico
  void removeLogsForMedication(String medicationId) {
    _logs.removeWhere((log) => log.medicationId == medicationId);
  }

  /// Calcula el porcentaje de adherencia general
  double calculateOverallAdherence(StatisticsPeriod period) {
    final filteredLogs = _getLogsForPeriod(period);
    if (filteredLogs.isEmpty) return 0.0;

    final taken = filteredLogs
        .where((log) => log.action == MedicationAction.taken)
        .length;
    return (taken / filteredLogs.length) * 100;
  }

  /// Calcula la adherencia por día de la semana
  List<DailyAdherence> calculateDailyAdherence(StatisticsPeriod period) {
    final filteredLogs = _getLogsForPeriod(period);
    final dailyData = <int, List<MedicationLog>>{};

    // Agrupar logs por día de la semana
    for (var log in filteredLogs) {
      dailyData.putIfAbsent(log.weekday, () => []).add(log);
    }

    // Calcular adherencia para cada día
    final result = <DailyAdherence>[];
    for (int i = 0; i < 7; i++) {
      final logsForDay = dailyData[i] ?? [];
      final taken = logsForDay
          .where((log) => log.action == MedicationAction.taken)
          .length;
      final total = logsForDay.length;
      final percentage = total > 0 ? (taken / total) * 100 : 0.0;

      result.add(
        DailyAdherence(
          weekday: i,
          percentage: percentage,
          taken: taken,
          total: total,
        ),
      );
    }

    return result;
  }

  /// Calcula la adherencia por medicamento
  List<MedicationAdherence> calculateMedicationAdherence(
    StatisticsPeriod period,
    List<Medication> medications,
  ) {
    final filteredLogs = _getLogsForPeriod(period);
    final result = <MedicationAdherence>[];

    for (var medication in medications) {
      final logsForMed = filteredLogs
          .where((log) => log.medicationId == medication.id)
          .toList();

      if (logsForMed.isEmpty) continue;

      final taken = logsForMed
          .where((log) => log.action == MedicationAction.taken)
          .length;
      final total = logsForMed.length;
      final percentage = (taken / total) * 100;

      result.add(
        MedicationAdherence(
          medicationId: medication.id,
          medicationName: medication.name,
          percentage: percentage,
          taken: taken,
          total: total,
          timesPerDay: medication.times.length,
        ),
      );
    }

    // Ordenar por porcentaje descendente
    result.sort((a, b) => b.percentage.compareTo(a.percentage));
    return result;
  }

  /// Filtra logs según el período seleccionado
  List<MedicationLog> _getLogsForPeriod(StatisticsPeriod period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case StatisticsPeriod.week:
        // Última semana (7 días)
        startDate = now.subtract(const Duration(days: 7));
        break;
      case StatisticsPeriod.month:
        // Último mes (30 días)
        startDate = now.subtract(const Duration(days: 30));
        break;
      case StatisticsPeriod.year:
        // Último año (365 días)
        startDate = now.subtract(const Duration(days: 365));
        break;
    }

    return _logs.where((log) => log.scheduledTime.isAfter(startDate)).toList();
  }

  /// Obtiene el total de medicamentos tomados
  int getTotalTaken(StatisticsPeriod period) {
    final filteredLogs = _getLogsForPeriod(period);
    return filteredLogs
        .where((log) => log.action == MedicationAction.taken)
        .length;
  }

  /// Obtiene el total de medicamentos omitidos
  int getTotalSkipped(StatisticsPeriod period) {
    final filteredLogs = _getLogsForPeriod(period);
    return filteredLogs
        .where((log) => log.action == MedicationAction.skipped)
        .length;
  }

  /// Obtiene el total de medicamentos pospuestos
  int getTotalSnoozed(StatisticsPeriod period) {
    final filteredLogs = _getLogsForPeriod(period);
    return filteredLogs
        .where((log) => log.action == MedicationAction.snoozed)
        .length;
  }

  /// Limpia todos los logs (para testing)
  void clearAllLogs() {
    _logs.clear();
  }

  /// Genera datos de prueba para demostración
  void generateMockData(List<Medication> medications) {
    _logs.clear();
    final now = DateTime.now();

    // Generar logs para los últimos 7 días
    for (int day = 0; day < 7; day++) {
      final date = now.subtract(Duration(days: day));

      for (var medication in medications) {
        for (var time in medication.times) {
          final scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );

          // Simular diferentes acciones con probabilidades
          MedicationAction action;
          DateTime? actionTime;

          final random = (day + time.hour) % 10;
          if (random < 7) {
            // 70% tomado
            action = MedicationAction.taken;
            actionTime = scheduledTime.add(Duration(minutes: random * 2));
          } else if (random < 9) {
            // 20% omitido
            action = MedicationAction.skipped;
          } else {
            // 10% pospuesto
            action = MedicationAction.snoozed;
            actionTime = scheduledTime.add(const Duration(minutes: 10));
          }

          _logs.add(
            MedicationLog(
              id: '${medication.id}_${scheduledTime.millisecondsSinceEpoch}',
              userId: 'mock_user', // Usuario de prueba
              medicationId: medication.id,
              medicationName: medication.name,
              scheduledTime: scheduledTime,
              actionTime: actionTime,
              action: action,
            ),
          );
        }
      }
    }

    debugPrint('Generados ${_logs.length} logs de prueba');
  }
}
