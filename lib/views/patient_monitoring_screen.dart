import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/patient_monitoring_viewmodel.dart';
import '../config/app_theme.dart';
import '../models/medication_log.dart';
import 'package:intl/intl.dart';

/// Pantalla de monitoreo de paciente para cuidadores
/// Muestra en tiempo real las acciones del paciente con sus medicamentos
class PatientMonitoringScreen extends StatelessWidget {
  final String patientId;

  const PatientMonitoringScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PatientMonitoringViewModel(patientId: patientId),
      child: const _PatientMonitoringContent(),
    );
  }
}

class _PatientMonitoringContent extends StatelessWidget {
  const _PatientMonitoringContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PatientMonitoringViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Monitoreo de Paciente'),
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        elevation: 0,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
          ? _buildError(context, viewModel.errorMessage!, isDark)
          : _buildContent(context, viewModel, isDark),
    );
  }

  /// Construye el mensaje de error
  Widget _buildError(BuildContext context, String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark
                  ? AppColors.textDark.withOpacity(0.5)
                  : AppColors.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el contenido principal
  Widget _buildContent(
    BuildContext context,
    PatientMonitoringViewModel viewModel,
    bool isDark,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // El stream se actualiza automáticamente
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del paciente
            _buildPatientInfo(viewModel, isDark),
            const SizedBox(height: 24),

            // Estadísticas rápidas
            _buildQuickStats(viewModel, isDark),
            const SizedBox(height: 24),

            // Título de actividad reciente
            Text(
              'Actividad Reciente (24h)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),

            // Lista de logs recientes
            _buildRecentLogs(viewModel, isDark),
          ],
        ),
      ),
    );
  }

  /// Construye la información del paciente
  Widget _buildPatientInfo(PatientMonitoringViewModel viewModel, bool isDark) {
    final patient = viewModel.patientInfo;
    if (patient == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: isDark
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.secondary.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 32,
              color: isDark ? AppColors.primary : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 16),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye las estadísticas rápidas
  Widget _buildQuickStats(PatientMonitoringViewModel viewModel, bool isDark) {
    final actionCounts = viewModel.actionCounts;
    final adherenceRate = viewModel.adherenceRate;

    return Row(
      children: [
        // Adherencia
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            label: 'Adherencia',
            value: '${adherenceRate.toStringAsFixed(0)}%',
            color: adherenceRate >= 80
                ? Colors.green
                : adherenceRate >= 50
                ? Colors.orange
                : Colors.red,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),

        // Tomados
        Expanded(
          child: _buildStatCard(
            icon: Icons.medication,
            label: 'Tomados',
            value: '${actionCounts[MedicationAction.taken] ?? 0}',
            color: Colors.green,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),

        // Omitidos
        Expanded(
          child: _buildStatCard(
            icon: Icons.cancel,
            label: 'Omitidos',
            value: '${actionCounts[MedicationAction.skipped] ?? 0}',
            color: Colors.red,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  /// Construye una tarjeta de estadística
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textDark.withOpacity(0.7)
                  : AppColors.textLight.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la lista de logs recientes
  Widget _buildRecentLogs(PatientMonitoringViewModel viewModel, bool isDark) {
    if (viewModel.recentLogs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: isDark
                    ? AppColors.textDark.withOpacity(0.3)
                    : AppColors.textLight.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay actividad reciente',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? AppColors.textDark.withOpacity(0.5)
                      : AppColors.textLight.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.recentLogs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = viewModel.recentLogs[index];
        return _buildLogCard(log, isDark);
      },
    );
  }

  /// Construye una tarjeta de log
  Widget _buildLogCard(MedicationLog log, bool isDark) {
    final actionColor = _getActionColor(log.action);
    final actionIcon = _getActionIcon(log.action);
    final actionText = _getActionText(log.action);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: actionColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          // Icono de acción
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(actionIcon, color: actionColor, size: 24),
          ),
          const SizedBox(width: 16),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.medicationName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 14,
                    color: actionColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatLogTime(log),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDark.withOpacity(0.6)
                        : AppColors.textLight.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene el color según la acción
  Color _getActionColor(MedicationAction action) {
    switch (action) {
      case MedicationAction.taken:
        return Colors.green;
      case MedicationAction.skipped:
        return Colors.red;
      case MedicationAction.snoozed:
        return Colors.orange;
    }
  }

  /// Obtiene el icono según la acción
  IconData _getActionIcon(MedicationAction action) {
    switch (action) {
      case MedicationAction.taken:
        return Icons.check_circle;
      case MedicationAction.skipped:
        return Icons.cancel;
      case MedicationAction.snoozed:
        return Icons.access_time;
    }
  }

  /// Obtiene el texto según la acción
  String _getActionText(MedicationAction action) {
    switch (action) {
      case MedicationAction.taken:
        return 'Medicamento tomado';
      case MedicationAction.skipped:
        return 'Medicamento omitido';
      case MedicationAction.snoozed:
        return 'Medicamento pospuesto';
    }
  }

  /// Formatea el tiempo del log
  String _formatLogTime(MedicationLog log) {
    final time = log.actionTime ?? log.scheduledTime;
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Justo ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}
