/// Modelo de Usuario para MemoryMedic
/// Representa un usuario autenticado con su rol (Paciente o Cuidador)

enum UserRole {
  patient, // Paciente - persona que toma medicamentos
  caregiver, // Cuidador - persona que cuida al paciente
}

class UserModel {
  final String uid;
  final String email;
  final String?
  displayName; // Nombre completo (para compatibilidad con Google Sign-In)
  final String? firstName; // Nombre
  final String? lastName; // Apellido
  final String? photoURL;
  final DateTime? dateOfBirth; // Fecha de nacimiento (opcional)
  final UserRole? role; // null si aún no ha seleccionado rol
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Datos adicionales según el rol
  final String? patientId; // Si es cuidador, ID del paciente que cuida
  final List<String>? caregiverIds; // Si es paciente, IDs de sus cuidadores
  final String?
  linkCode; // Código de vinculación de 6 dígitos (solo para pacientes)

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.photoURL,
    this.dateOfBirth,
    this.role,
    DateTime? createdAt,
    this.updatedAt,
    this.patientId,
    this.caregiverIds,
    this.linkCode,
  }) : createdAt = createdAt ?? DateTime.now();

  // Getters de conveniencia
  bool get hasRole => role != null;
  bool get isPatient => role == UserRole.patient;
  bool get isCaregiver => role == UserRole.caregiver;
  String get roleName => role == UserRole.patient ? 'Paciente' : 'Cuidador';

  /// Obtener el nombre completo del usuario
  /// Prioriza firstName + lastName, luego displayName
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (displayName != null) return displayName!;
    return 'Usuario';
  }

  /// Obtener solo el primer nombre para notificaciones personalizadas
  String get preferredName =>
      firstName ?? displayName?.split(' ').first ?? 'Usuario';

  /// Verificar si el perfil está completo (tiene nombre y apellido)
  bool get hasCompleteProfile => firstName != null && lastName != null;

  // Copiar con modificaciones
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? photoURL,
    DateTime? dateOfBirth,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? patientId,
    List<String>? caregiverIds,
    String? linkCode,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoURL: photoURL ?? this.photoURL,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      patientId: patientId ?? this.patientId,
      caregiverIds: caregiverIds ?? this.caregiverIds,
      linkCode: linkCode ?? this.linkCode,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'photoURL': photoURL,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'role': role?.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'patientId': patientId,
      'caregiverIds': caregiverIds,
      'linkCode': linkCode,
    };
  }

  // Crear desde Map de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      photoURL: map['photoURL'],
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'])
          : null,
      role: map['role'] != null
          ? UserRole.values.firstWhere((e) => e.name == map['role'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      patientId: map['patientId'],
      caregiverIds: map['caregiverIds'] != null
          ? List<String>.from(map['caregiverIds'])
          : null,
      linkCode: map['linkCode'],
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, role: ${role?.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel && other.uid == uid && other.email == email;
  }

  @override
  int get hashCode => uid.hashCode ^ email.hashCode;
}
