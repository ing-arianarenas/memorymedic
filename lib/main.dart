import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';
import 'views/profile_setup_screen.dart';
import 'views/role_selection_screen.dart';
import 'services/notification_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';

// NavigatorKey global para navegación desde notificaciones
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reducir logs en modo release
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar servicio de notificaciones
  await NotificationService.initializeNotifications();
  await NotificationService.requestPermissions();

  runApp(const MemoryMedicApp());
}

/// Aplicación principal de MemoryMedic
class MemoryMedicApp extends StatefulWidget {
  const MemoryMedicApp({super.key});

  @override
  _MemoryMedicAppState createState() => _MemoryMedicAppState();
}

class _MemoryMedicAppState extends State<MemoryMedicApp> {
  @override
  void initState() {
    super.initState();
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: (ReceivedAction receivedAction) async {
        if (receivedAction.buttonKeyPressed == 'SNOOZE') {
          // Re-notify after 5 minutes
          NotificationService.showMedicationNotification(
            title: receivedAction.title ?? '',
            body: receivedAction.body ?? '',
            imageUrl: receivedAction.bigPicture ?? '',
            payload: receivedAction.payload ?? {},
            schedule: NotificationInterval(
              interval: 300, // 5 minutes
              timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
              repeats: false,
            ),
          );
        } else if (receivedAction.buttonKeyPressed == 'DISMISS') {
          // Cancel all scheduled notifications
          AwesomeNotifications().cancelAllSchedules();
        }
      },
      onNotificationExpiredMethod: (ReceivedNotification receivedNotification) async {
        // Re-notify after 1 minute if the notification times out
        NotificationService.showMedicationNotification(
          title: receivedNotification.title ?? '',
          body: receivedNotification.body ?? '',
          imageUrl: receivedNotification.bigPicture ?? '',
          payload: receivedNotification.payload ?? {},
          schedule: NotificationInterval(
            interval: 60, // 1 minute
            timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
            repeats: false,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: Builder(
        builder: (context) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Forzar formato 12 horas en toda la aplicación
              alwaysUse24HourFormat: false,
            ),
            child: MaterialApp(
              title: 'MemoryMedic',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey, // Clave global para navegación
              // Configuración de localizaciones
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('es', 'ES'), // Español
                Locale('en', 'US'), // Inglés
              ],
              locale: const Locale('es', 'ES'), // Idioma por defecto
              // Temas claro y oscuro
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system, // Sigue el tema del sistema
              // Pantalla inicial con AuthWrapper
              home: const AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper de autenticación que decide qué pantalla mostrar
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    // Mostrar loading mientras se verifica el estado
    if (authViewModel.status == AuthStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Si no está autenticado, mostrar login
    if (!authViewModel.isAuthenticated) {
      return const LoginScreen();
    }

    final currentUser = authViewModel.currentUser;

    // Si está autenticado pero no tiene perfil completo, mostrar configuración de perfil
    if (currentUser != null && !currentUser.hasCompleteProfile) {
      return const ProfileSetupScreen();
    }

    // Si está autenticado pero no tiene rol, mostrar selección de rol
    if (!authViewModel.hasRole) {
      return const RoleSelectionScreen();
    }

    // Si está autenticado y tiene rol, mostrar home
    return const HomeScreen();
  }
}
