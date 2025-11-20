import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/statistics_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/statistics_service.dart';
import '../widgets/circular_progress_chart.dart';
import '../widgets/daily_adherence_chart.dart';

/// Pantalla de estadísticas de adherencia
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatisticsScreenContent();
  }
}

class _StatisticsScreenContent extends StatelessWidget {
  const _StatisticsScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<StatisticsViewModel>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 16),

              // Contenido con scroll
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Selector de período
                      _buildPeriodSelector(context, viewModel),
                      const SizedBox(height: 12),

                      // Gráfico circular de adherencia
                      _buildAdherenceCircle(context, viewModel),
                      const SizedBox(height: 12),

                      // Gráfico de barras diario
                      _buildDailyChart(context, viewModel),
                      const SizedBox(height: 12),

                      // Lista de medicamentos
                      _buildMedicationList(context, viewModel),
                    ],
                  ),
                ),
              ),

              // Footer con botón exportar
              const SizedBox(height: 16),
              _buildExportButton(context, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  /// Header con botón atrás y título
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          iconSize: 28,
        ),
        const Expanded(
          child: Center(
            child: Text(
              'Estadísticas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 44), // Espaciador para centrar el título
      ],
    );
  }

  /// Selector de período (Semana, Mes, Año)
  Widget _buildPeriodSelector(
    BuildContext context,
    StatisticsViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[700] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _PeriodButton(
            label: 'Semana',
            isSelected: viewModel.selectedPeriod == StatisticsPeriod.week,
            onTap: () => viewModel.changePeriod(StatisticsPeriod.week),
          ),
          _PeriodButton(
            label: 'Mes',
            isSelected: viewModel.selectedPeriod == StatisticsPeriod.month,
            onTap: () => viewModel.changePeriod(StatisticsPeriod.month),
          ),
          _PeriodButton(
            label: 'Año',
            isSelected: viewModel.selectedPeriod == StatisticsPeriod.year,
            onTap: () => viewModel.changePeriod(StatisticsPeriod.year),
          ),
        ],
      ),
    );
  }

  /// Gráfico circular de adherencia general
  Widget _buildAdherenceCircle(
    BuildContext context,
    StatisticsViewModel viewModel,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressChart(percentage: viewModel.overallAdherence),
      ),
    );
  }

  /// Gráfico de barras de adherencia diaria
  Widget _buildDailyChart(BuildContext context, StatisticsViewModel viewModel) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adherencia diaria',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          DailyAdherenceChart(dailyData: viewModel.dailyAdherence),
        ],
      ),
    );
  }

  /// Lista de medicamentos con su adherencia individual
  Widget _buildMedicationList(
    BuildContext context,
    StatisticsViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final medicationAdherence = viewModel.medicationAdherence;

    if (medicationAdherence.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No hay datos de adherencia disponibles',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: medicationAdherence.map((med) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MedicationAdherenceItem(adherence: med),
          );
        }).toList(),
      ),
    );
  }

  /// Botón de exportar PDF
  Widget _buildExportButton(
    BuildContext context,
    StatisticsViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final authViewModel = context.watch<AuthViewModel>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleExportPDF(context, viewModel, authViewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'EXPORTAR PDF',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Maneja la exportación del PDF
  Future<void> _handleExportPDF(
    BuildContext context,
    StatisticsViewModel viewModel,
    AuthViewModel authViewModel,
  ) async {
    // Obtener nombre del usuario ANTES de mostrar el dialog
    final userName = authViewModel.currentUser?.fullName;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Generar PDF
      final pdfFile = await viewModel.exportToPDF(userName: userName);

      // Cerrar loading
      if (context.mounted) Navigator.pop(context);

      if (pdfFile != null) {
        // Mostrar opciones
        if (context.mounted) {
          _showPdfOptions(context, viewModel, pdfFile);
        }
      } else {
        // Error al generar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al generar el PDF'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar loading
      if (context.mounted) Navigator.pop(context);

      // Mostrar error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Muestra opciones para el PDF generado
  void _showPdfOptions(
    BuildContext context,
    StatisticsViewModel viewModel,
    File pdfFile,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✅ PDF Generado Exitosamente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ubicación: ${pdfFile.path}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botón Ver PDF
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  viewModel.openPDF(pdfFile);
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Ver PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón Compartir
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  viewModel.sharePDF(pdfFile);
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartir PDF'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón Cerrar
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de período (Semana, Mes, Año)
class _PeriodButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.secondary
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item de adherencia de medicamento
class _MedicationAdherenceItem extends StatelessWidget {
  final MedicationAdherence adherence;

  const _MedicationAdherenceItem({required this.adherence});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Icono
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.secondary
                : const Color(0xFFB2FFFB),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.medication,
            color: isDark
                ? const Color(0xFFB2FFFB)
                : theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 16),

        // Información del medicamento
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                adherence.medicationName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                '${adherence.timesPerDay} ${adherence.timesPerDay == 1 ? 'toma' : 'tomas'} por día',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),

        // Porcentaje
        Text(
          '${adherence.percentage.toInt()}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark
                ? theme.colorScheme.primary
                : theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
