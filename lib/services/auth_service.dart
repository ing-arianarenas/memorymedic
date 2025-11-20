/// Servicio de Autenticación para MemoryMedic
/// Maneja login, registro, Google Sign-In y gestión de usuarios en Firestore
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseService _db = DatabaseService();

  // Stream del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual de Firebase
  User? get currentUser => _auth.currentUser;

  // Obtener UserModel del usuario actual desde Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Intentar obtener el usuario de Firestore
      UserModel? userModel = await _db.getUser(user.uid);

      // Si no existe, crear el documento base
      if (userModel == null) {
        userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoURL: user.photoURL,
          role: null,
        );

        // Crear el documento en Firestore
        await _db.createUser(userModel);
      }

      return userModel;
    } catch (e) {
      throw 'Error al obtener datos del usuario: $e';
    }
  }

  // Registro con email y contraseña
  Future<UserModel?> registerWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;
      if (user == null) return null;

      // Actualizar displayName si se proporcionó
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      // Crear documento en Firestore (sin rol aún)
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        displayName: displayName ?? user.displayName,
        photoURL: user.photoURL,
        role: null, // Se asignará después en RoleSelectionScreen
      );

      await _db.createUser(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar usuario: $e';
    }
  }

  // Login con email y contraseña
  Future<UserModel?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user == null) return null;

      // Obtener datos del usuario desde Firestore
      return await getCurrentUserModel();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al iniciar sesión: $e';
    }
  }

  // Login con Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Iniciar flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Usuario canceló

      // Obtener detalles de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear credencial de Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;
      if (user == null) return null;

      // Verificar si es usuario nuevo o existente
      final existingUser = await _db.getUser(user.uid);

      if (existingUser == null) {
        // Usuario nuevo - crear documento sin rol
        final userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          displayName: user.displayName,
          photoURL: user.photoURL,
          role: null, // Se asignará después
        );

        await _db.createUser(userModel);
        return userModel;
      } else {
        // Usuario existente - obtener datos
        return existingUser;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al iniciar sesión con Google: $e';
    }
  }

  // Actualizar rol del usuario
  Future<void> updateUserRole(UserRole role) async {
    final user = currentUser;
    if (user == null) throw 'No hay usuario autenticado';

    try {
      await _db.updateUserRole(user.uid, role);
    } catch (e) {
      throw 'Error al actualizar rol: $e';
    }
  }

  // Actualizar datos del usuario
  Future<void> updateUserData(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) throw 'No hay usuario autenticado';

    try {
      await _db.updateUser(user.uid, data);
    } catch (e) {
      throw 'Error al actualizar datos: $e';
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw 'Error al cerrar sesión: $e';
    }
  }

  // Enviar email de verificación
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) throw 'No hay usuario autenticado';

    try {
      await user.sendEmailVerification();
    } catch (e) {
      throw 'Error al enviar email de verificación: $e';
    }
  }

  // Restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al enviar email de restablecimiento: $e';
    }
  }

  // Manejar excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Intenta iniciar sesión.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta al administrador.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
