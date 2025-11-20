import 'dart:async';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';
import '../services/notification_service.dart';
import '../services/statistics_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

/// ViewModel para la pantalla principal de medicamentos
class HomeViewModel extends ChangeNotifier {
  final NotificationService _notificationService = notificationService;
  final StatisticsService _statisticsService = StatisticsService();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  // Lista de medicamentos
  List<Medication> _medications = [];
  StreamSubscription? _medicationsSubscription;

  // Getter para obtener la lista de medicamentos
  List<Medication> get medications => _medications;


  /// Constructor
  HomeViewModel() {
    _setupNotificationCallbacks();
    _loadMedicationLogsFromFirestore();
    _loadMedications();
  }

  /// Carga los logs de medicación desde Firestore
  Future<void> _loadMedicationLogsFromFirestore() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No hay usuario autenticado, no se pueden cargar logs');
        return;
      }

      debugPrint('📥 Cargando logs de medicación desde Firestore...');

      // Obtener logs de los últimos 30 días
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final logsData = await _databaseService.getUserMedicationLogs(
        currentUser.uid,
        startDate: thirtyDaysAgo,
      );

      debugPrint('📥 Logs obtenidos: ${logsData.length}');

      // Convertir a objetos MedicationLog y agregar al servicio de estadísticas
      for (final logData in logsData) {
        try {
          final log = MedicationLog.fromMap(logData);
          _statisticsService.addLog(log);
        } catch (e) {
          debugPrint('⚠️ Error al parsear log: $e');
        }
      }

      debugPrint('✅ Logs cargados exitosamente en memoria');
    } catch (e) {
      debugPrint('❌ Error al cargar logs desde Firestore: $e');
    }
  }

  /// Carga los medicamentos desde Firestore
  Future<void> _loadMedications() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No hay usuario autenticado, no se pueden cargar medicamentos');
        return;
      }

      // Obtener el UserModel completo para verificar el rol
      final userModel = await _authService.getCurrentUserModel();
      if (userModel == null) {
        debugPrint('⚠️ No se pudo obtener el modelo de usuario');
        return;
      }

      debugPrint('📥 Cargando medicamentos para usuario: ${userModel.roleName}');

      if (userModel.isCaregiver && userModel.patientId != null) {
        // Cuidador: cargar medicamentos del paciente vinculado
        debugPrint('👨‍⚕️ Cargando medicamentos del paciente: ${userModel.patientId}');
        _loadCaregiverMedications(userModel.uid, userModel.patientId!);
      } else if (userModel.isPatient) {
        // Paciente: cargar sus propios medicamentos
        debugPrint('👤 Cargando medicamentos propios del paciente');
        _loadPatientMedications(userModel.uid);
      } else {
        debugPrint('⚠️ Usuario sin rol asignado o cuidador sin paciente vinculado');
      }
    } catch (e) {
      debugPrint('❌ Error al cargar medicamentos: $e');
    }
  }

  /// Carga los medicamentos del paciente (para pacientes)
  void _loadPatientMedications(String userId) {
    // Cancelar suscripción anterior si existe
    _medicationsSubscription?.cancel();

    // Escuchar cambios en tiempo real
    _medicationsSubscription = _databaseService
        .userMedicationsStream(userId)
        .listen(
          (medicationsData) {
            debugPrint('📥 Medicamentos recibidos (Paciente): ${medicationsData.length}');

            _medications = medicationsData.map((medData) {
              try {
                return Medication.fromMap(medData);
              } catch (e) {
                debugPrint('⚠️ Error al parsear medicamento: $e');
                return null;
              }
            }).whereType<Medication>().toList();

            // Programar notificaciones para medicamentos activos
            _scheduleNotificationsForActiveMedications();
            
            debugPrint('✅ Medicamentos cargados: ${_medications.length}');
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ Error en stream de medicamentos: $error');
          },
        );

    // Carga inicial
    _databaseService.getUserMedications(userId).then((medicationsData) {
      debugPrint('📥 Medicamentos iniciales (Paciente): ${medicationsData.length}');

      _medications = medicationsData.map((medData) {
        try {
          return Medication.fromMap(medData);
        } catch (e) {
          debugPrint('⚠️ Error al parsear medicamento: $e');
          return null;
        }
      }).whereType<Medication>().toList();

      // Programar notificaciones para medicamentos activos
      _scheduleNotificationsForActiveMedications();
      
      debugPrint('✅ Medicamentos iniciales cargados: ${_medications.length}');
      notifyListeners();
    }).catchError((error) {
      debugPrint('❌ Error al cargar medicamentos iniciales: $error');
    });
  }

  /// Carga los medicamentos del paciente vinculado (para cuidadores)
  void _loadCaregiverMedications(String caregiverId, String patientId) {
    // Cancelar suscripción anterior si existe
    _medicationsSubscription?.cancel();

    // Escuchar cambios en tiempo real
    _medicationsSubscription = _databaseService
        .caregiverMedicationsStream(caregiverId)
        .listen(
          (medicationsData) {
            debugPrint('📥 Medicamentos recibidos (Cuidador): ${medicationsData.length}');

            _medications = medicationsData.map((medData) {
              try {
                return Medication.fromMap(medData);
              } catch (e) {
                debugPrint('⚠️ Error al parsear medicamento: $e');
                return null;
              }
            }).whereType<Medication>().toList();

            // Programar notificaciones para cuidadores (al mismo tiempo que el paciente)
            _scheduleNotificationsForCaregiver(patientId);
            
            debugPrint('✅ Medicamentos del paciente cargados: ${_medications.length}');
            notifyListeners();
          },
          onError: (error) {
            debugPrint('❌ Error en stream de medicamentos (Cuidador): $error');
          },
        );

    // Carga inicial
    _databaseService.getCaregiverMedications(caregiverId).then((medicationsData) {
      debugPrint('📥 Medicamentos iniciales (Cuidador): ${medicationsData.length}');

      _medications = medicationsData.map((medData) {
        try {
          return Medication.fromMap(medData);
        } catch (e) {
          debugPrint('⚠️ Error al parsear medicamento: $e');
          return null;
        }
      }).whereType<Medication>().toList();

      // Programar notificaciones para cuidadores (al mismo tiempo que el paciente)
      _scheduleNotificationsForCaregiver(patientId);
      
      debugPrint('✅ Medicamentos del paciente cargados: ${_medications.length}');
      notifyListeners();
    }).catchError((error) {
      debugPrint('❌ Error al cargar medicamentos iniciales (Cuidador): $error');
    });
  }

  /// Programa notificaciones para medicamentos activos (para pacientes)
  Future<void> _scheduleNotificationsForActiveMedications() async {
    for (final medication in _medications) {
      if (medication.isActive) {
        await _notificationService.scheduleMedicationReminders(medication);
      }
    }
  }

  /// Programa notificaciones para cuidadores (al mismo tiempo que el paciente)
  Future<void> _scheduleNotificationsForCaregiver(String patientId) async {
    // Programar notificaciones para todos los medicamentos activos del paciente
    // Las notificaciones serán las mismas que las del paciente
    for (final medication in _medications) {
      if (medication.isActive) {
        // Programar la misma notificación para el cuidador
        await _notificationService.scheduleMedicationReminders(medication);
      }
    }
  }

  /// Configura los callbacks del servicio de notificaciones
  void _setupNotificationCallbacks() {
    _notificationService.onGetMedication = getMedicationById;
    _notificationService.onNotificationAction = handleNotificationAction;
  }

  /// Obtiene un medicamento por su ID
  Medication? getMedicationById(String id) {
    try {
      return _medications.firstWhere((med) => med.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Maneja las acciones de notificación
  void handleNotificationAction(String medicationId, String action) async {
    debugPrint(
      'Acción de notificación: $action para medicamento: $medicationId',
    );

    // Obtener el medicamento
    final medication = getMedicationById(medicationId);
    if (medication == null) return;

    // Obtener el usuario actual
    final currentUser = await _authService.getCurrentUserModel();
    if (currentUser == null) {
      debugPrint('❌ No hay usuario autenticado, no se puede guardar el log');
      return;
    }

    // Si es cuidador, no guardar logs (solo el paciente puede guardar logs)
    if (currentUser.isCaregiver) {
      debugPrint('👨‍⚕️ Cuidador detectado: No se guardan logs, solo el paciente puede registrar acciones');
      return;
    }

    // Crear log según la acción
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      medication.scheduleTime.hour,
      medication.scheduleTime.minute,
    );

    MedicationAction logAction;
    DateTime? actionTime;

    switch (action) {
      case 'take':
        logAction = MedicationAction.taken;
        actionTime = now;
        break;
      case 'skip':
        logAction = MedicationAction.skipped;
        break;
      case 'snooze':
        logAction = MedicationAction.snoozed;
        actionTime = now;
        break;
      default:
        return;
    }

    // Crear el log con userId del paciente
    final log = MedicationLog(
      id: '${medicationId}_${now.millisecondsSinceEpoch}',
      userId: currentUser.uid, // ID del paciente
      medicationId: medicationId,
      medicationName: medication.name,
      scheduledTime: scheduledTime,
      actionTime: actionTime,
      action: logAction,
    );

    // Guardar en memoria local (para estadísticas inmediatas)
    _statisticsService.addLog(log);
    debugPrint(
      '✅ Log registrado en memoria: ${log.action} - ${log.medicationName}',
    );

    // Guardar en Firestore (para persistencia y sincronización)
    try {
      await _databaseService.createMedicationLog(log.toMap());
      debugPrint('✅ Log guardado en Firestore: ${log.id}');
    } catch (e) {
      debugPrint('❌ Error al guardar log en Firestore: $e');
    }
  }

  /// Alterna el estado activo/inactivo de un medicamento
  void toggleMedicationStatus(String medicationId) async {
    // Verificar si es cuidador (solo lectura)
    final userModel = await _authService.getCurrentUserModel();
    if (userModel?.isCaregiver ?? false) {
      debugPrint('👨‍⚕️ Los cuidadores no pueden modificar medicamentos');
      return;
    }

    final index = _medications.indexWhere((med) => med.id == medicationId);
    if (index != -1) {
      final wasActive = _medications[index].isActive;
      _medications[index] = _medications[index].copyWith(isActive: !wasActive);

      // Si se activa, programar notificaciones; si se desactiva, cancelarlas
      if (_medications[index].isActive) {
        await _notificationService.scheduleMedicationReminders(
          _medications[index],
        );
      } else {
        await _notificationService.cancelMedicationReminders(medicationId);
      }

      notifyListeners();
    }
  }

  /// Agrega un nuevo medicamento
  Future<void> addMedication(Medication medication) async {
    String? medicationId;
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No hay usuario autenticado');
        throw 'Usuario no autenticado';
      }

      // Guardar en Firestore primero para obtener el ID real de Firestore
      final medicationData = medication.toMap();
      medicationData['userId'] = currentUser.uid;

      medicationId = await _databaseService.createMedication(
        medicationData,
      );
      debugPrint('✅ Medicamento guardado en Firestore: $medicationId');

      // Actualizar el medicamento con el ID real de Firestore
      final medicationWithId = medication.copyWith(id: medicationId);

      // Agregar a la lista local con el ID correcto (para UI inmediata)
      _medications.add(medicationWithId);
      notifyListeners();

      // Programar notificaciones si el medicamento está activo
      if (medication.isActive) {
        await _notificationService.scheduleMedicationReminders(medicationWithId);
      }
    } catch (e) {
      debugPrint('❌ Error al agregar medicamento: $e');
      // Remover de la lista local si falló (usar el ID original o el de Firestore si existe)
      _medications.removeWhere((med) => med.id == medication.id || (medicationId != null && med.id == medicationId));
      notifyListeners();
      rethrow;
    }
  }

  /// Elimina un medicamento
  Future<void> removeMedication(String medicationId) async {
    try {
      // Cancelar notificaciones antes de eliminar
      await _notificationService.cancelMedicationReminders(medicationId);

      // Eliminar de la lista local primero (para UI inmediata)
      _medications.removeWhere((med) => med.id == medicationId);
      notifyListeners();

      // Eliminar de Firestore
      await _databaseService.deleteMedication(medicationId);
      debugPrint('✅ Medicamento eliminado de Firestore: $medicationId');
    } catch (e) {
      debugPrint('❌ Error al eliminar medicamento: $e');
      rethrow;
    }
  }

  /// Actualiza un medicamento existente
  Future<void> updateMedication(Medication medication) async {
    try {
      final index = _medications.indexWhere((med) => med.id == medication.id);
      if (index != -1) {
        // Actualizar en la lista local primero (para UI inmediata)
        _medications[index] = medication;
        notifyListeners();

        // Actualizar en Firestore
        final medicationData = medication.toMap();
        final currentUser = _authСervice.currentUser;
        if (currentUser != null) {
          medicationData['userId'] = currentUser.uid;
        }

        await _databaseService.updateMedication(medication.id, medicationData);
        debugPrint('✅ Medicamento actualizado en Firestore: ${medication.id}');

        // Reprogramar notificaciones
        await _notificationService.cancelMedicationReminders(medication.id);
        if (medication.isActive) {
          await _notificationService.scheduleMedicationReminders(medication);
        }
      }
    } catch (e) {
      debugPrint('❌ Error al actualizar medicamento: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _medicationsSubscription?.cancel();
    super.dispose();
  }
}
