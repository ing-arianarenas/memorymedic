import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'patient_monitoring_screen.dart';

/// Pantalla para que el cuidador ingrese el código de vinculación del paciente
class CaregiverLinkScreen extends StatefulWidget {
  const CaregiverLinkScreen({super.key});

  @override
  State<CaregiverLinkScreen> createState() => _CaregiverLinkScreenState();
}

class _CaregiverLinkScreenState extends State<CaregiverLinkScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Vincular con el paciente usando el código a través de Firebase Functions
  Future<void> _linkWithPatient() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el código del paciente')),
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    final success = await authViewModel.linkCaregiverToPatient(code);

    if (success) {
      if (!mounted) return;
      final patientId = authViewModel.currentUser?.patientId;
      if (patientId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Vinculado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PatientMonitoringScreen(patientId: patientId),
          ),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage ?? 'No se pudo obtener el ID del paciente después de la vinculación.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? 'Ocurrió un error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Vincular con Paciente'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.link,
              size: 100,
              color: isDark ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Ingresa el código del paciente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Solicita el código de 6 dígitos a tu paciente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
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
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
              onSubmitted: (_) => _linkWithPatient(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authViewModel.isLoading ? null : _linkWithPatient,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDark ? AppColors.primary : AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: authViewModel.isLoading
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primary : AppColors.secondary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        '¿Cómo funciona?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('1. Solicita al paciente que genere su código de vinculación.'),
                  SizedBox(height: 8),
                  Text('2. Ingresa el código de 6 dígitos en el campo de arriba.'),
                  SizedBox(height: 8),
                  Text('3. Una vez vinculado, podrás monitorear sus medicamentos en tiempo real.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
