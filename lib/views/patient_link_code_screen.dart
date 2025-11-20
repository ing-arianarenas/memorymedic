import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/database_service.dart';

/// Pantalla para que el paciente genere y comparta su código de vinculación
class PatientLinkCodeScreen extends StatefulWidget {
  const PatientLinkCodeScreen({super.key});

  @override
  State<PatientLinkCodeScreen> createState() => _PatientLinkCodeScreenState();
}

class _PatientLinkCodeScreenState extends State<PatientLinkCodeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _linkCode;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateCode();
  }

  /// Cargar código existente o generar uno nuevo
  Future<void> _loadOrGenerateCode() async {
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

      // Si ya tiene código, usarlo
      if (currentUser.linkCode != null && currentUser.linkCode!.isNotEmpty) {
        setState(() {
          _linkCode = currentUser.linkCode;
          _isLoading = false;
        });
      } else {
        // Generar nuevo código
        final code = await _databaseService.generateLinkCode(currentUser.uid);
        setState(() {
          _linkCode = code;
          _isLoading = false;
        });

        // Actualizar el usuario en el ViewModel
        await authViewModel.refreshUser();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Copiar código al portapapeles
  void _copyCode() {
    if (_linkCode != null) {
      Clipboard.setData(ClipboardData(text: _linkCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
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
        title: const Text('Código de Vinculación'),
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError(isDark)
          : _buildContent(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.red[300] : Colors.red[700],
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrGenerateCode,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono principal
          Icon(
            Icons.qr_code_2,
            size: 100,
            color: isDark ? AppColors.primary : AppColors.secondary,
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            'Comparte este código',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu cuidador necesita este código para vincularse contigo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 32),

          // Código de vinculación
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.secondary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'CÓDIGO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _linkCode ?? '------',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.primary : AppColors.secondary,
                    letterSpacing: 8,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón copiar
          ElevatedButton.icon(
            onPressed: _copyCode,
            icon: const Icon(Icons.copy),
            label: const Text('Copiar Código'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isDark ? AppColors.primary : AppColors.secondary,
              foregroundColor: Colors.white,
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
                      'Instrucciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInstruction('1', 'Comparte este código con tu cuidador'),
                _buildInstruction(
                  '2',
                  'El cuidador debe ingresar el código en su app',
                ),
                _buildInstruction(
                  '3',
                  'Una vez vinculado, podrá monitorear tus medicamentos',
                ),
              ],
            ),
          ),
        ],
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
