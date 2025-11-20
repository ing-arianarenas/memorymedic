import 'dart:async';
import 'package:flutter/material.dart';
import '../models/medication_log.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

/// ViewModel para monitorear en tiempo real las acciones del paciente
/// Usado por cuidadores para ver si el paciente está tomando sus medicamentos
class PatientMonitoringViewModel extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final String patientId;

  // Estado
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _patientInfo;
  List<MedicationLog> _recentLogs = [];
  StreamSubscription? _logsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get patientInfo => _patientInfo;
  List<MedicationLog> get recentLogs => _recentLogs;

  /// Constructor
  PatientMonitoringViewModel({required this.patientId}) {
    _initialize();
  }

  /// Inicializa el monitoreo
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint(
        '🔵 [PatientMonitoring] Inicializando monitoreo del paciente: $patientId',
      );

      // Cargar información del paciente
      await _loadPatientInfo();

      // Escuchar logs en tiempo real
      _listenToPatientLogs();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [PatientMonitoring] Error al inicializar: $e');
      _errorMessage = 'Error al cargar información del paciente';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga la información del paciente
  Future<void> _loadPatientInfo() async {
    try {
      final userData = await _databaseService.getUser(patientId);
      if (userData != null) {
        _patientInfo = userData;
        debugPrint(
          '✅ [PatientMonitoring] Información del paciente cargada: ${_patientInfo?.fullName}',
        );
      } else {
        throw 'Paciente no encontrado';
      }
    } catch (e) {
      debugPrint('❌ [PatientMonitoring] Error al cargar info del paciente: $e');
      rethrow;
    }
  }

  /// Escucha los logs del paciente en tiempo real
  void _listenToPatientLogs() {
    debugPrint('👂 [PatientMonitoring] Escuchando logs del paciente...');

    // Obtener logs de las últimas 24 horas
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    _logsSubscription = _databaseService
        .patientMedicationLogsStream(patientId, limit: 50, since: yesterday)
        .listen(
          (logsData) {
            debugPrint(
              '📥 [PatientMonitoring] Logs recibidos: ${logsData.length}',
            );

            _recentLogs = logsData
                .map((logData) {
                  try {
                    return MedicationLog.fromMap(logData);
                  } catch (e) {
                    debugPrint(
                      '⚠️ [PatientMonitoring] Error al parsear log: $e',
                    );
                    return null;
                  }
                })
                .whereType<MedicationLog>()
                .toList();

            debugPrint(
              '✅ [PatientMonitoring] Logs parseados: ${_recentLogs.length}',
            );
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ [PatientMonitoring] Error en stream de logs: $error');
            _errorMessage = 'Error al cargar logs del paciente';
            notifyListeners();
          },
        );
  }

  /// Obtiene el último log de un medicamento específico
  MedicationLog? getLastLogForMedication(String medicationId) {
    try {
      return _recentLogs.firstWhere((log) => log.medicationId == medicationId);
    } catch (e) {
      return null;
    }
  }

  /// Calcula la adherencia del paciente (últimas 24 horas)
  double get adherenceRate {
    if (_recentLogs.isEmpty) return 0.0;

    final takenLogs = _recentLogs
        .where((log) => log.action == MedicationAction.taken)
        .length;
    return (takenLogs / _recentLogs.length) * 100;
  }

  /// Obtiene el conteo de acciones por tipo
  Map<MedicationAction, int> get actionCounts {
    final counts = <MedicationAction, int>{
      MedicationAction.taken: 0,
      MedicationAction.skipped: 0,
      MedicationAction.snoozed: 0,
    };

    for (final log in _recentLogs) {
      counts[log.action] = (counts[log.action] ?? 0) + 1;
    }

    return counts;
  }

  @override
  void dispose() {
    _logsSubscription?.cancel();
    super.dispose();
  }
}
