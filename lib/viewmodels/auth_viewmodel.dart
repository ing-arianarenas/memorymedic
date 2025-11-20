/// ViewModel de Autenticación para MemoryMedic
/// Maneja la lógica de negocio de autenticación y estado del usuario
library;

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: "us-central1");

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get hasRole => _currentUser?.hasRole ?? false;

  AuthViewModel() {
    _init();
  }

  // Inicializar - escuchar cambios de autenticación
  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadCurrentUser();
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  // Cargar datos del usuario actual
  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUserModel();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al cargar usuario: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Registro con email y contraseña
  Future<bool> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Error al registrar usuario';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Login con email y contraseña
  Future<bool> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      }

      _errorMessage = 'Error al iniciar sesión';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Login con Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      }

      // Usuario canceló el login
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Actualizar perfil del usuario (nombre, apellido, fecha de nacimiento)
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final data = <String, dynamic>{};

      if (firstName != null) data['firstName'] = firstName;
      if (lastName != null) data['lastName'] = lastName;
      if (dateOfBirth != null) {
        data['dateOfBirth'] = dateOfBirth.toIso8601String();
      }

      // También actualizar displayName para compatibilidad
      if (firstName != null && lastName != null) {
        data['displayName'] = '$firstName $lastName';
      }

      await _authService.updateUserData(data);

      // Recargar usuario
      await _loadCurrentUser();

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Actualizar rol del usuario
  Future<bool> updateUserRole(UserRole role) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.updateUserRole(role);

      // Recargar usuario
      await _loadCurrentUser();

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Vincular cuidador a paciente usando Firebase Functions
  Future<bool> linkCaregiverToPatient(String patientCode) async {
    _setLoading(true);
    _clearError();

    try {
      final callable = _functions.httpsCallable('linkCaregiverToPatient');
      final result = await callable.call(<String, dynamic>{
        'patientCode': patientCode,
      });

      // La función se ejecutó correctamente, ahora refrescamos los datos del usuario
      await refreshUser();
      _setLoading(false);
      return true;

    } on FirebaseFunctionsException catch (e) {
      _errorMessage = e.message ?? "Ocurrió un error al vincular.";
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "Ocurrió un error inesperado: $e";
      _setLoading(false);
      return false;
    }
  }


  // Cerrar sesión
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  // Enviar email de verificación
  Future<bool> sendEmailVerification() async {
    _clearError();

    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Restablecer contraseña
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  /// Refrescar los datos del usuario actual desde Firestore
  /// Útil después de actualizar el perfil o vincular cuidador/paciente
  Future<void> refreshUser() async {
    try {
      await _loadCurrentUser();
    } catch (e) {
      debugPrint('Error al refrescar usuario: $e');
    }
  }
}
