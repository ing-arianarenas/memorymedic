/// Servicio de Base de Datos para MemoryMedic
/// Maneja todas las operaciones de Firestore (CRUD)
/// Separado del AuthService para mejor organización
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    _initializeFirestore();
  }

  // Instancia de Firestore (usa la base de datos predeterminada "(default)")
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Configurar Firestore para mejor manejo de conexión
  void _initializeFirestore() {
    // Habilitar persistencia offline (ya está habilitado por defecto en Flutter)
    // Configurar timeouts más largos para evitar errores de conexión
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ============================================================================
  // COLECCIONES
  // ============================================================================

  /// Referencia a la colección de usuarios
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Referencia a la colección de medicamentos
  CollectionReference get _medicationsCollection =>
      _firestore.collection('medications');

  /// Referencia a la colección de logs de medicación
  CollectionReference get _medicationLogsCollection =>
      _firestore.collection('medication_logs');

  /// Referencia a la colección de medicamentos para cuidadores
  CollectionReference get _caregiverMedicationsCollection =>
      _firestore.collection('caregiver_medications');

  /// Referencia a la colección de logs para cuidadores
  CollectionReference get _caregiverLogsCollection =>
      _firestore.collection('caregiver_logs');

  // ============================================================================
  // OPERACIONES DE USUARIOS
  // ============================================================================

  /// Crear un nuevo usuario en Firestore
  /// Se llama después de que Firebase Auth crea la cuenta
  /// Usa merge: true para no sobrescribir datos existentes
  Future<void> createUser(UserModel user) async {
    try {
      // Usar set() con merge: true para crear o actualizar
      // Esto evita errores si el documento ya existe parcialmente
      await _usersCollection
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw 'Error al crear usuario en Firestore: $e';
    }
  }

  /// Obtener datos de un usuario por su UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw 'Error al obtener usuario: $e';
    }
  }

  /// Verificar si un usuario existe en Firestore
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw 'Error al verificar existencia de usuario: $e';
    }
  }

  /// Actualizar el rol del usuario (Paciente o Cuidador)
  /// Si el documento no existe, lo crea con el rol especificado
  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      final docRef = _usersCollection.doc(uid);

      // Usar set() con merge: true para crear o actualizar
      // Esto crea el documento si no existe, o actualiza solo los campos especificados
      await docRef.set({
        'role': role.name,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Error al actualizar rol del usuario: $e';
    }
  }

  /// Actualizar datos generales del usuario
  /// Si el documento no existe, lo crea con los datos especificados
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      // Agregar timestamp de actualización
      data['updatedAt'] = DateTime.now().toIso8601String();

      // Usar set() con merge: true para crear o actualizar
      await _usersCollection.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      throw 'Error al actualizar usuario: $e';
    }
  }

  /// Actualizar nombre de usuario
  Future<void> updateUserDisplayName(String uid, String displayName) async {
    try {
      await updateUser(uid, {'displayName': displayName});
    } catch (e) {
      throw 'Error al actualizar nombre: $e';
    }
  }

  /// Actualizar foto de perfil
  Future<void> updateUserPhotoURL(String uid, String photoURL) async {
    try {
      await updateUser(uid, {'photoURL': photoURL});
    } catch (e) {
      throw 'Error al actualizar foto de perfil: $e';
    }
  }

  /// Vincular un cuidador a un paciente
  Future<void> addCaregiverToPatient(
    String patientUid,
    String caregiverUid,
  ) async {
    try {
      // Actualizar paciente: agregar cuidador a la lista
      await _usersCollection.doc(patientUid).set({
        'caregiverIds': FieldValue.arrayUnion([caregiverUid]),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Actualizar cuidador: establecer el paciente que cuida
      await _usersCollection.doc(caregiverUid).set({
        'patientId': patientUid,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Error al vincular cuidador con paciente: $e';
    }
  }

  /// Desvincular un cuidador de un paciente
  Future<void> removeCaregiverFromPatient(
    String patientUid,
    String caregiverUid,
  ) async {
    try {
      // Actualizar paciente: remover cuidador de la lista
      await _usersCollection.doc(patientUid).set({
        'caregiverIds': FieldValue.arrayRemove([caregiverUid]),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Actualizar cuidador: remover el paciente
      await _usersCollection.doc(caregiverUid).set({
        'patientId': null,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Error al desvincular cuidador de paciente: $e';
    }
  }

  /// Obtener todos los cuidadores de un paciente
  Future<List<UserModel>> getPatientCaregivers(String patientUid) async {
    try {
      final patient = await getUser(patientUid);
      if (patient == null ||
          patient.caregiverIds == null ||
          patient.caregiverIds!.isEmpty) {
        return [];
      }

      final caregivers = <UserModel>[];
      for (final caregiverId in patient.caregiverIds!) {
        final caregiver = await getUser(caregiverId);
        if (caregiver != null) {
          caregivers.add(caregiver);
        }
      }

      return caregivers;
    } catch (e) {
      throw 'Error al obtener cuidadores del paciente: $e';
    }
  }

  /// Obtener el paciente que cuida un cuidador
  Future<UserModel?> getCaregiverPatient(String caregiverUid) async {
    try {
      final caregiver = await getUser(caregiverUid);
      if (caregiver == null || caregiver.patientId == null) {
        return null;
      }

      return await getUser(caregiver.patientId!);
    } catch (e) {
      throw 'Error al obtener paciente del cuidador: $e';
    }
  }

  /// Eliminar usuario de Firestore
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw 'Error al eliminar usuario: $e';
    }
  }

  // ============================================================================
  // OPERACIONES DE MEDICAMENTOS (Para futuras implementaciones)
  // ============================================================================

  /// Crear un nuevo medicamento
  Future<String> createMedication(Map<String, dynamic> medicationData) async {
    try {
      medicationData['createdAt'] = DateTime.now().toIso8601String();
      medicationData['updatedAt'] = DateTime.now().toIso8601String();

      final docRef = await _medicationsCollection.add(medicationData);
      final medicationId = docRef.id;

      // Sincronizar con cuidadores si el usuario es paciente
      final userId = medicationData['userId'];
      await _syncMedicationToCaregiversOnCreate(
        userId,
        medicationId,
        medicationData,
      );

      return medicationId;
    } catch (e) {
      throw 'Error al crear medicamento: $e';
    }
  }

  /// Obtener medicamentos de un usuario
  Future<List<Map<String, dynamic>>> getUserMedications(String userId) async {
    try {
      final querySnapshot = await _medicationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw 'Error al obtener medicamentos: $e';
    }
  }

  /// Obtener medicamentos del paciente vinculado (para cuidadores)
  Future<List<Map<String, dynamic>>> getCaregiverMedications(String caregiverId) async {
    try {
      final querySnapshot = await _caregiverMedicationsCollection
          .where('caregiverId', isEqualTo: caregiverId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Usar medicationId como id principal para mantener consistencia
        return {
          'id': data['medicationId'] ?? doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw 'Error al obtener medicamentos del cuidador: $e';
    }
  }

  /// Stream de medicamentos del cuidador (para ver en tiempo real)
  Stream<List<Map<String, dynamic>>> caregiverMedicationsStream(String caregiverId) {
    return _caregiverMedicationsCollection
        .where('caregiverId', isEqualTo: caregiverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': data['medicationId'] ?? doc.id,
              ...data,
            };
          }).toList(),
        );
  }

  /// Actualizar un medicamento
  Future<void> updateMedication(
    String medicationId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _medicationsCollection
          .doc(medicationId)
          .set(data, SetOptions(merge: true));

      // Sincronizar con cuidadores
      final userId = data['userId'];
      await _syncMedicationToCaregiversOnUpdate(userId, medicationId, data);
    } catch (e) {
      throw 'Error al actualizar medicamento: $e';
    }
  }

  /// Eliminar un medicamento
  Future<void> deleteMedication(String medicationId) async {
    try {
      await _medicationsCollection.doc(medicationId).delete();

      // Eliminar de las colecciones de cuidadores
      await _deleteMedicationFromCaregivers(medicationId);
    } catch (e) {
      throw 'Error al eliminar medicamento: $e';
    }
  }

  // ============================================================================
  // OPERACIONES DE LOGS DE MEDICACIÓN (Para futuras implementaciones)
  // ============================================================================

  /// Crear un log de medicación (tomado, omitido, pospuesto)
  Future<String> createMedicationLog(Map<String, dynamic> logData) async {
    try {
      logData['createdAt'] = DateTime.now().toIso8601String();

      final docRef = await _medicationLogsCollection.add(logData);
      final logId = docRef.id;

      // Sincronizar con cuidadores
      final userId = logData['userId'];
      await _syncLogToCaregiversOnCreate(userId, logId, logData);

      return logId;
    } catch (e) {
      throw 'Error al crear log de medicación: $e';
    }
  }

  /// Obtener logs de medicación de un usuario
  Future<List<Map<String, dynamic>>> getUserMedicationLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _medicationLogsCollection.where(
        'userId',
        isEqualTo: userId,
      );

      if (startDate != null) {
        query = query.where(
          'createdAt',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        query = query.where(
          'createdAt',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw 'Error al obtener logs de medicación: $e';
    }
  }

  // ============================================================================
  // STREAMS (Para escuchar cambios en tiempo real)
  // ============================================================================

  /// Stream de datos de usuario (escucha cambios en tiempo real)
  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  /// Stream de medicamentos de un usuario
  Stream<List<Map<String, dynamic>>> userMedicationsStream(String userId) {
    return _medicationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  /// Stream de logs de medicación de un usuario (para monitoreo en tiempo real)
  /// Útil para que los cuidadores vean en tiempo real las acciones del paciente
  Stream<List<Map<String, dynamic>>> userMedicationLogsStream(
    String userId, {
    int? limit,
  }) {
    Query query = _medicationLogsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList(),
    );
  }

  /// Stream de logs de medicación de un paciente específico (para cuidadores)
  /// Permite al cuidador monitorear en tiempo real las acciones del paciente
  Stream<List<Map<String, dynamic>>> patientMedicationLogsStream(
    String patientId, {
    int? limit,
    DateTime? since,
  }) {
    Query query = _medicationLogsCollection
        .where('userId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true);

    if (since != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: since.toIso8601String(),
      );
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList(),
    );
  }

  // ============================================================================
  // VINCULACIÓN PACIENTE-CUIDADOR
  // ============================================================================

  /// Generar un código de vinculación único de 6 dígitos para un paciente
  Future<String> generateLinkCode(String patientId) async {
    try {
      String code;
      bool isUnique = false;

      // Intentar hasta encontrar un código único
      while (!isUnique) {
        // Generar código aleatorio de 6 dígitos
        code = _generateRandomCode();

        // Verificar si el código ya existe
        final existingUser = await _usersCollection
            .where('linkCode', isEqualTo: code)
            .limit(1)
            .get();

        if (existingUser.docs.isEmpty) {
          isUnique = true;

          // Guardar el código en el perfil del paciente
          await _usersCollection.doc(patientId).set({
            'linkCode': code,
            'updatedAt': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));

          return code;
        }
      }

      throw 'No se pudo generar un código único';
    } catch (e) {
      throw 'Error al generar código de vinculación: $e';
    }
  }

  /// Generar código aleatorio de 6 dígitos
  String _generateRandomCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// Vincular un cuidador con un paciente usando el código de vinculación
  /// Método mejorado con transacciones y múltiples intentos
  Future<UserModel> linkCaregiverToPatient({
    required String caregiverId,
    required String linkCode,
  }) async {
    try {
      UserModel? patient;
      
      // Intentar múltiples métodos de búsqueda para mayor robustez
      // Método 1: Buscar por linkCode (requiere índice)
      try {
        final patientQuery = await _usersCollection
            .where('linkCode', isEqualTo: linkCode)
            .where('role', isEqualTo: 'patient')
            .limit(1)
            .get();

        if (patientQuery.docs.isNotEmpty) {
          final patientDoc = patientQuery.docs.first;
          final patientData = patientDoc.data() as Map<String, dynamic>;
          patient = UserModel.fromMap({'uid': patientDoc.id, ...patientData});
        }
      } catch (e) {
        // Si falla por índice, intentar método alternativo
        debugPrint('⚠️ Búsqueda por linkCode falló: $e');
      }

      // Método 2: Buscar todos los pacientes y filtrar localmente (más lento pero más robusto)
      if (patient == null) {
        try {
          final allPatients = await _usersCollection
              .where('role', isEqualTo: 'patient')
              .get();
          
          for (var doc in allPatients.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['linkCode'] == linkCode) {
              patient = UserModel.fromMap({'uid': doc.id, ...data});
              break;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Búsqueda alternativa falló: $e');
        }
      }

      if (patient == null) {
        throw 'Código de vinculación inválido o paciente no encontrado';
      }

      final patientId = patient.uid;

      // Usar transacción para asegurar consistencia
      return await _firestore.runTransaction((transaction) async {
        // Obtener documentos actualizados
        final patientRef = _usersCollection.doc(patientId);
        final caregiverRef = _usersCollection.doc(caregiverId);

        final patientDoc = await transaction.get(patientRef);
        final caregiverDoc = await transaction.get(caregiverRef);

        if (!patientDoc.exists) {
          throw 'Paciente no encontrado';
        }

        final patientData = patientDoc.data() as Map<String, dynamic>;
        
        // Verificar rol del paciente
        if (patientData['role'] != 'patient') {
          throw 'El código no corresponde a un paciente';
        }

        // Obtener la lista actual de cuidadores del paciente
        List<String> caregiverIds = [];
        if (patientData['caregiverIds'] != null) {
          caregiverIds = List<String>.from(patientData['caregiverIds']);
        }

        // Verificar si el cuidador ya está vinculado
        if (caregiverIds.contains(caregiverId)) {
          throw 'Ya estás vinculado con este paciente';
        }

        // Verificar que el cuidador no tenga otro paciente
        if (caregiverDoc.exists) {
          final caregiverData = caregiverDoc.data() as Map<String, dynamic>;
          if (caregiverData['patientId'] != null && caregiverData['patientId'] != patientId) {
            throw 'Ya estás vinculado con otro paciente';
          }
        }

        // Agregar el cuidador a la lista
        caregiverIds.add(caregiverId);

        // Actualizar en la transacción
        transaction.update(patientRef, {
          'caregiverIds': caregiverIds,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        transaction.set(caregiverRef, {
          'patientId': patientId,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        // Retornar el UserModel del paciente desde los datos actualizados
        return UserModel.fromMap({'uid': patientId, ...patientData});
      }).then((linkedPatient) async {
        // Sincronizar medicamentos después de la transacción
        await _syncPatientMedicationsToCaregiver(linkedPatient.uid, caregiverId);
        return linkedPatient;
      });
    } catch (e) {
      if (e.toString().contains('permission') || e.toString().contains('permission-denied')) {
        throw 'Error de permisos: Verifica tu conexión e intenta nuevamente';
      } else if (e.toString().contains('unavailable') || e.toString().contains('network')) {
        throw 'Error de conexión: Verifica tu internet e intenta nuevamente';
      }
      throw 'Error al vincular cuidador: $e';
    }
  }

  /// Vincular cuidador con paciente usando email (más robusto, no requiere índices)
  Future<UserModel> linkCaregiverToPatientByEmail({
    required String caregiverId,
    required String patientEmail,
  }) async {
    try {
      // Buscar paciente por email (más directo, no requiere índices compuestos)
      final patientQuery = await _usersCollection
          .where('email', isEqualTo: patientEmail.toLowerCase().trim())
          .limit(1)
          .get();

      if (patientQuery.docs.isEmpty) {
        throw 'No se encontró un paciente con ese correo electrónico';
      }

      final patientDoc = patientQuery.docs.first;
      final patientData = patientDoc.data() as Map<String, dynamic>;
      
      // Verificar que sea un paciente
      if (patientData['role'] != 'patient') {
        throw 'El correo no corresponde a un paciente';
      }

      final patientId = patientDoc.id;

      // Usar transacción para asegurar consistencia
      return await _firestore.runTransaction((transaction) async {
        final patientRef = _usersCollection.doc(patientId);
        final caregiverRef = _usersCollection.doc(caregiverId);

        final patientDoc = await transaction.get(patientRef);
        final caregiverDoc = await transaction.get(caregiverRef);

        if (!patientDoc.exists) {
          throw 'Paciente no encontrado';
        }

        final patientData = patientDoc.data() as Map<String, dynamic>;
        List<String> caregiverIds = [];
        if (patientData['caregiverIds'] != null) {
          caregiverIds = List<String>.from(patientData['caregiverIds']);
        }

        if (caregiverIds.contains(caregiverId)) {
          throw 'Ya estás vinculado con este paciente';
        }

        if (caregiverDoc.exists) {
          final caregiverData = caregiverDoc.data() as Map<String, dynamic>;
          if (caregiverData['patientId'] != null && caregiverData['patientId'] != patientId) {
            throw 'Ya estás vinculado con otro paciente';
          }
        }

        caregiverIds.add(caregiverId);

        transaction.update(patientRef, {
          'caregiverIds': caregiverIds,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        transaction.set(caregiverRef, {
          'patientId': patientId,
          'updatedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        return UserModel.fromMap({'uid': patientId, ...patientData});
      }).then((patient) async {
        await _syncPatientMedicationsToCaregiver(patient.uid, caregiverId);
        return patient;
      });
    } catch (e) {
      if (e.toString().contains('permission') || e.toString().contains('permission-denied')) {
        throw 'Error de permisos: Verifica tu conexión e intenta nuevamente';
      } else if (e.toString().contains('unavailable') || e.toString().contains('network')) {
        throw 'Error de conexión: Verifica tu internet e intenta nuevamente';
      }
      throw 'Error al vincular por correo: $e';
    }
  }

  /// Sincronizar medicamentos del paciente a la colección del cuidador
  Future<void> _syncPatientMedicationsToCaregiver(
    String patientId,
    String caregiverId,
  ) async {
    try {
      // Obtener todos los medicamentos del paciente
      final medicationsSnapshot = await _medicationsCollection
          .where('userId', isEqualTo: patientId)
          .get();

      // Crear documentos en caregiver_medications para cada medicamento
      final batch = _firestore.batch();

      for (var doc in medicationsSnapshot.docs) {
        final medicationData = doc.data() as Map<String, dynamic>;
        final caregiverMedDocId = '${caregiverId}_${doc.id}';

        batch.set(_caregiverMedicationsCollection.doc(caregiverMedDocId), {
          ...medicationData,
          'medicationId': doc.id,
          'patientId': patientId,
          'caregiverId': caregiverId,
          'syncedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      // No lanzar error, solo registrar
      print('Error al sincronizar medicamentos: $e');
    }
  }

  /// Sincronizar un medicamento nuevo a todos los cuidadores del paciente
  Future<void> _syncMedicationToCaregiversOnCreate(
    String patientId,
    String medicationId,
    Map<String, dynamic> medicationData,
  ) async {
    try {
      // Obtener el documento del paciente para ver sus cuidadores
      final patientDoc = await _usersCollection.doc(patientId).get();
      if (!patientDoc.exists) return;

      final patientData = patientDoc.data() as Map<String, dynamic>;
      final caregiverIds = patientData['caregiverIds'] as List<dynamic>? ?? [];

      if (caregiverIds.isEmpty) return;

      // Crear documentos para cada cuidador
      final batch = _firestore.batch();

      for (var caregiverId in caregiverIds) {
        final caregiverMedDocId = '${caregiverId}_$medicationId';
        batch.set(_caregiverMedicationsCollection.doc(caregiverMedDocId), {
          ...medicationData,
          'medicationId': medicationId,
          'patientId': patientId,
          'caregiverId': caregiverId,
          'syncedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error al sincronizar medicamento nuevo: $e');
    }
  }

  /// Sincronizar actualización de medicamento a todos los cuidadores
  Future<void> _syncMedicationToCaregiversOnUpdate(
    String patientId,
    String medicationId,
    Map<String, dynamic> medicationData,
  ) async {
    try {
      // Obtener el documento del paciente para ver sus cuidadores
      final patientDoc = await _usersCollection.doc(patientId).get();
      if (!patientDoc.exists) return;

      final patientData = patientDoc.data() as Map<String, dynamic>;
      final caregiverIds = patientData['caregiverIds'] as List<dynamic>? ?? [];

      if (caregiverIds.isEmpty) return;

      // Actualizar documentos para cada cuidador
      final batch = _firestore.batch();

      for (var caregiverId in caregiverIds) {
        final caregiverMedDocId = '${caregiverId}_$medicationId';
        batch.set(
          _caregiverMedicationsCollection.doc(caregiverMedDocId),
          {
            ...medicationData,
            'medicationId': medicationId,
            'patientId': patientId,
            'caregiverId': caregiverId,
            'syncedAt': DateTime.now().toIso8601String(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
    } catch (e) {
      print('Error al sincronizar actualización de medicamento: $e');
    }
  }

  /// Eliminar medicamento de las colecciones de todos los cuidadores
  Future<void> _deleteMedicationFromCaregivers(String medicationId) async {
    try {
      // Buscar todos los documentos que contengan este medicationId
      final caregiverMedsSnapshot = await _caregiverMedicationsCollection
          .where('medicationId', isEqualTo: medicationId)
          .get();

      if (caregiverMedsSnapshot.docs.isEmpty) return;

      // Eliminar todos los documentos encontrados
      final batch = _firestore.batch();

      for (var doc in caregiverMedsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error al eliminar medicamento de cuidadores: $e');
    }
  }

  /// Sincronizar un log nuevo a todos los cuidadores del paciente
  Future<void> _syncLogToCaregiversOnCreate(
    String patientId,
    String logId,
    Map<String, dynamic> logData,
  ) async {
    try {
      // Obtener el documento del paciente para ver sus cuidadores
      final patientDoc = await _usersCollection.doc(patientId).get();
      if (!patientDoc.exists) return;

      final patientData = patientDoc.data() as Map<String, dynamic>;
      final caregiverIds = patientData['caregiverIds'] as List<dynamic>? ?? [];

      if (caregiverIds.isEmpty) return;

      // Crear documentos para cada cuidador
      final batch = _firestore.batch();

      for (var caregiverId in caregiverIds) {
        final caregiverLogDocId = '${caregiverId}_$logId';
        batch.set(_caregiverLogsCollection.doc(caregiverLogDocId), {
          ...logData,
          'logId': logId,
          'patientId': patientId,
          'caregiverId': caregiverId,
          'syncedAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error al sincronizar log nuevo: $e');
    }
  }

  /// Desvincular un cuidador de un paciente
  Future<void> unlinkCaregiverFromPatient({
    required String caregiverId,
    required String patientId,
  }) async {
    try {
      // Obtener datos del paciente
      final patientDoc = await _usersCollection.doc(patientId).get();
      if (!patientDoc.exists) {
        throw 'Paciente no encontrado';
      }

      final patientData = patientDoc.data() as Map<String, dynamic>;
      List<String> caregiverIds = [];
      if (patientData['caregiverIds'] != null) {
        caregiverIds = List<String>.from(patientData['caregiverIds']);
      }

      // Remover el cuidador de la lista
      caregiverIds.remove(caregiverId);

      // Actualizar el documento del paciente
      await _usersCollection.doc(patientId).set({
        'caregiverIds': caregiverIds,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      // Actualizar el documento del cuidador (remover patientId)
      await _usersCollection.doc(caregiverId).set({
        'patientId': null,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Error al desvincular cuidador: $e';
    }
  }
}
