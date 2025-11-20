import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'patient_monitoring_screen.dart';

/// Pantalla para que el cuidador ingrese el código de vinculación del paciente
class CaregiverLinkScreen extends StatefulWidget {
  const CaregiverLinkScreen({super.key});

  @override
  State<CaregiverLinkScreen> createState() => _CaregiverLinkScreenState();
}

class _CaregiverLinkScreenState extends State<CaregiverLinkScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _useEmail = false; // Alternar entre código y email

  @override
  void dispose() {
    _codeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Vincular con el paciente usando código o email
  Future<void> _linkWithPatient() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;

      if (currentUser == null) {
        throw 'Usuario no autenticado';
      }

      UserModel patient;

      if (_useEmail) {
        // Método 1: Vincular por email (más robusto, no requiere índices)
        final email = _emailController.text.trim().toLowerCase();

        if (email.isEmpty) {
          throw 'Por favor ingresa un correo electrónico';
        }

        if (!email.contains('@') || !email.contains('.')) {
          throw 'Por favor ingresa un correo electrónico válido';
        }

        patient = await _databaseService.linkCaregiverToPatientByEmail(
          caregiverId: currentUser.uid,
          patientEmail: email,
        );
      } else {
        // Método 2: Vincular por código
        final code = _codeController.text.trim();

        if (code.isEmpty) {
          throw 'Por favor ingresa un código';
        }

        if (code.length != 6) {
          throw 'El código debe tener 6 dígitos';
        }

        patient = await _databaseService.linkCaregiverToPatient(
          caregiverId: currentUser.uid,
          linkCode: code,
        );
      }

      // Actualizar el usuario en el ViewModel
      await authViewModel.refreshUser();

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vinculado exitosamente con ${patient.fullName}'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a la pantalla de monitoreo
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PatientMonitoringScreen(patientId: patient.uid),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Vincular con Paciente'),
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icono principal
            Icon(
              Icons.link,
              size: 100,
              color: isDark ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(height: 24),

            // Título
            Text(
              _useEmail ? 'Ingresa el correo' : 'Ingresa el código',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _useEmail
                  ? 'Ingresa el correo electrónico del paciente'
                  : 'Solicita el código de 6 dígitos a tu paciente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),

            // Toggle entre código y email
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleButton(
                  'Código',
                  !_useEmail,
                  () => setState(() {
                    _useEmail = false;
                    _errorMessage = null;
                    _emailController.clear();
                  }),
                  isDark,
                ),
                const SizedBox(width: 16),
                _buildToggleButton(
                  'Correo',
                  _useEmail,
                  () => setState(() {
                    _useEmail = true;
                    _errorMessage = null;
                    _codeController.clear();
                  }),
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Campo de código o email
            _useEmail
                ? TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.primary : AppColors.secondary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'paciente@ejemplo.com',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.primary : AppColors.secondary,
                          width: 2,
                        ),
                      ),
                      errorText: _errorMessage,
                      prefixIcon: Icon(
                        Icons.email,
                        color: isDark ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                    onChanged: (value) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _linkWithPatient(),
                  )
                : TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: isDark ? AppColors.primary : AppColors.secondary,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.secondary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.primary : AppColors.secondary,
                          width: 2,
                        ),
                      ),
                      errorText: _errorMessage,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _linkWithPatient(),
                  ),
            const SizedBox(height: 24),

            // Botón vincular
            ElevatedButton(
              onPressed: _isLoading ? null : _linkWithPatient,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDark
                    ? AppColors.primary
                    : AppColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Vincular',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 32),

            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primary : AppColors.secondary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? AppColors.primary : AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '¿Cómo funciona?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction(
                    '1',
                    _useEmail
                        ? 'Solicita el correo electrónico del paciente'
                        : 'Solicita al paciente que genere su código de vinculación',
                  ),
                  _buildInstruction(
                    '2',
                    _useEmail
                        ? 'Ingresa el correo electrónico en el campo de arriba (método más confiable)'
                        : 'Ingresa el código de 6 dígitos en el campo de arriba',
                  ),
                  _buildInstruction(
                    '3',
                    'Una vez vinculado, podrás monitorear sus medicamentos en tiempo real',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : AppColors.secondary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primary : AppColors.secondary)
                : (isDark ? AppColors.primary.withOpacity(0.3) : AppColors.secondary.withOpacity(0.3)),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.primary : AppColors.secondary),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
