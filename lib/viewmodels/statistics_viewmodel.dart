import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../services/statistics_service.dart';
import '../services/pdf_service.dart';

/// ViewModel para la pantalla de estadísticas
class StatisticsViewModel extends ChangeNotifier {
  final StatisticsService _statisticsService = StatisticsService();

  // Período seleccionado
  StatisticsPeriod _selectedPeriod = StatisticsPeriod.week;

  // Lista de medicamentos (pasada desde HomeViewModel)
  List<Medication> _medications = [];

  /// Getter para el período seleccionado
  StatisticsPeriod get selectedPeriod => _selectedPeriod;

  /// Getter para medicamentos
  List<Medication> get medications => _medications;

  /// Constructor
  StatisticsViewModel({List<Medication>? medications}) {
    if (medications != null) {
      _medications = medications;
    }
  }

  /// Cambia el período seleccionado
  void changePeriod(StatisticsPeriod period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  /// Obtiene el nombre del período seleccionado
  String get periodName {
    switch (_selectedPeriod) {
      case StatisticsPeriod.week:
        return 'Semana';
      case StatisticsPeriod.month:
        return 'Mes';
      case StatisticsPeriod.year:
        return 'Año';
    }
  }

  /// Calcula la adherencia general
  double get overallAdherence {
    return _statisticsService.calculateOverallAdherence(_selectedPeriod);
  }

  /// Obtiene la adherencia diaria
  List<DailyAdherence> get dailyAdherence {
    return _statisticsService.calculateDailyAdherence(_selectedPeriod);
  }

  /// Obtiene la adherencia por medicamento
  List<MedicationAdherence> get medicationAdherence {
    return _statisticsService.calculateMedicationAdherence(
      _selectedPeriod,
      _medications,
    );
  }

  /// Obtiene el total de medicamentos tomados
  int get totalTaken {
    return _statisticsService.getTotalTaken(_selectedPeriod);
  }

  /// Obtiene el total de medicamentos omitidos
  int get totalSkipped {
    return _statisticsService.getTotalSkipped(_selectedPeriod);
  }

  /// Obtiene el total de medicamentos pospuestos
  int get totalSnoozed {
    return _statisticsService.getTotalSnoozed(_selectedPeriod);
  }

  /// Actualiza la lista de medicamentos
  void updateMedications(List<Medication> medications) {
    _medications = medications;
    notifyListeners();
  }

  /// Exporta estadísticas a PDF
  Future<File?> exportToPDF({String? userName}) async {
    try {
      debugPrint('🔵 [PDF] Iniciando exportación de PDF...');
      debugPrint('🔵 [PDF] Usuario: $userName');
      debugPrint('🔵 [PDF] Período: $periodName');
      debugPrint('🔵 [PDF] Adherencia: $overallAdherence%');
      debugPrint('🔵 [PDF] Medicamentos: ${_medications.length}');
      debugPrint('🔵 [PDF] Logs: ${_statisticsService.logs.length}');

      final pdfService = PdfService();

      // Generar el PDF
      debugPrint('🔵 [PDF] Llamando a generateStatisticsPdf...');
      final pdfFile = await pdfService.generateStatisticsPdf(
        period: periodName,
        adherencePercentage: overallAdherence,
        totalTaken: totalTaken,
        totalSkipped: totalSkipped,
        totalSnoozed: totalSnoozed,
        medications: _medications,
        logs: _statisticsService.logs,
        userName: userName,
      );

      debugPrint('✅ [PDF] PDF generado exitosamente: ${pdfFile.path}');
      return pdfFile;
    } catch (e, stackTrace) {
      debugPrint('❌ [PDF] Error al generar PDF: $e');
      debugPrint('❌ [PDF] StackTrace: $stackTrace');
      return null;
    }
  }

  /// Comparte el PDF generado
  Future<void> sharePDF(File pdfFile) async {
    try {
      final pdfService = PdfService();
      await pdfService.sharePdf(pdfFile);
    } catch (e) {
      debugPrint('Error al compartir PDF: $e');
    }
  }

  /// Abre el PDF para visualización
  Future<void> openPDF(File pdfFile) async {
    try {
      final pdfService = PdfService();
      await pdfService.openPdf(pdfFile);
    } catch (e) {
      debugPrint('Error al abrir PDF: $e');
    }
  }
}
