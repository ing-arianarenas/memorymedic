/// Servicio para generar y exportar PDFs de estadísticas
/// Usa los paquetes pdf y printing para crear documentos profesionales
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';

class PdfService {
  // Singleton pattern
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  /// Genera un PDF con las estadísticas de medicación
  Future<File> generateStatisticsPdf({
    required String period,
    required double adherencePercentage,
    required int totalTaken,
    required int totalSkipped,
    required int totalSnoozed,
    required List<Medication> medications,
    required List<MedicationLog> logs,
    String? userName,
  }) async {
    debugPrint('🟢 [PdfService] Iniciando generación de PDF...');

    final pdf = pw.Document();
    debugPrint('🟢 [PdfService] Documento PDF creado');

    // Cargar fuente personalizada (opcional)
    debugPrint('🟢 [PdfService] Cargando fuentes...');
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    debugPrint('🟢 [PdfService] Fuentes cargadas correctamente');

    // Agregar página al PDF
    debugPrint('🟢 [PdfService] Agregando página al PDF...');
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(userName, fontBold),
            pw.SizedBox(height: 20),

            // Información del período
            _buildPeriodInfo(period, font, fontBold),
            pw.SizedBox(height: 20),

            // Resumen de adherencia
            _buildAdherenceSummary(
              adherencePercentage,
              totalTaken,
              totalSkipped,
              totalSnoozed,
              font,
              fontBold,
            ),
            pw.SizedBox(height: 20),

            // Gráfico de adherencia (simplificado)
            _buildAdherenceChart(
              totalTaken,
              totalSkipped,
              totalSnoozed,
              font,
              fontBold,
            ),
            pw.SizedBox(height: 20),

            // Lista de medicamentos
            _buildMedicationsList(medications, logs, font, fontBold),
            pw.SizedBox(height: 20),

            // Footer
            _buildFooter(font),
          ];
        },
      ),
    );
    debugPrint('🟢 [PdfService] Página agregada correctamente');

    // Guardar el PDF
    debugPrint('🟢 [PdfService] Guardando PDF...');
    final file = await _savePdf(pdf);
    debugPrint('🟢 [PdfService] PDF guardado en: ${file.path}');
    return file;
  }

  /// Construye el header del PDF
  pw.Widget _buildHeader(String? userName, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'MemoryMedic',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 28,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Reporte de Adherencia a Medicación',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        if (userName != null) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            'Paciente: $userName',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 14,
              color: PdfColors.grey800,
            ),
          ),
        ],
        pw.Divider(thickness: 2, color: PdfColors.blue700),
      ],
    );
  }

  /// Construye la información del período
  pw.Widget _buildPeriodInfo(String period, pw.Font font, pw.Font fontBold) {
    final now = DateTime.now();
    final formattedDate =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Período', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text(
                period,
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Fecha de generación',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                formattedDate,
                style: pw.TextStyle(font: fontBold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el resumen de adherencia
  pw.Widget _buildAdherenceSummary(
    double adherencePercentage,
    int totalTaken,
    int totalSkipped,
    int totalSnoozed,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final total = totalTaken + totalSkipped + totalSnoozed;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue700, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Adherencia General',
            style: pw.TextStyle(font: fontBold, fontSize: 18),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            '${adherencePercentage.toStringAsFixed(1)}%',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 48,
              color: _getAdherenceColor(adherencePercentage),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Tomados',
                totalTaken,
                total,
                PdfColors.green,
                font,
                fontBold,
              ),
              _buildStatItem(
                'Omitidos',
                totalSkipped,
                total,
                PdfColors.red,
                font,
                fontBold,
              ),
              _buildStatItem(
                'Pospuestos',
                totalSnoozed,
                total,
                PdfColors.orange,
                font,
                fontBold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye un item de estadística
  pw.Widget _buildStatItem(
    String label,
    int value,
    int total,
    PdfColor color,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;

    return pw.Column(
      children: [
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
          child: pw.Center(
            child: pw.Text(
              value.toString(),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 24,
                color: PdfColors.white,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 12)),
        pw.Text(
          '${percentage.toStringAsFixed(1)}%',
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// Construye un gráfico de barras simple
  pw.Widget _buildAdherenceChart(
    int totalTaken,
    int totalSkipped,
    int totalSnoozed,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final total = totalTaken + totalSkipped + totalSnoozed;
    if (total == 0) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        child: pw.Text(
          'No hay datos suficientes para mostrar el gráfico',
          style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey),
        ),
      );
    }

    final takenWidth = (totalTaken / total) * 400;
    final skippedWidth = (totalSkipped / total) * 400;
    final snoozedWidth = (totalSnoozed / total) * 400;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Distribución de Acciones',
          style: pw.TextStyle(font: fontBold, fontSize: 14),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            if (takenWidth > 0)
              pw.Container(
                width: takenWidth,
                height: 40,
                color: PdfColors.green,
              ),
            if (skippedWidth > 0)
              pw.Container(
                width: skippedWidth,
                height: 40,
                color: PdfColors.red,
              ),
            if (snoozedWidth > 0)
              pw.Container(
                width: snoozedWidth,
                height: 40,
                color: PdfColors.orange,
              ),
          ],
        ),
      ],
    );
  }

  /// Construye la lista de medicamentos
  pw.Widget _buildMedicationsList(
    List<Medication> medications,
    List<MedicationLog> logs,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detalle por Medicamento',
          style: pw.TextStyle(font: fontBold, fontSize: 14),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Medicamento', fontBold, isHeader: true),
                _buildTableCell('Tomados', fontBold, isHeader: true),
                _buildTableCell('Omitidos', fontBold, isHeader: true),
                _buildTableCell('Adherencia', fontBold, isHeader: true),
              ],
            ),
            // Rows
            ...medications.map((med) {
              final medLogs = logs
                  .where((log) => log.medicationId == med.id)
                  .toList();
              final taken = medLogs
                  .where((log) => log.action == MedicationAction.taken)
                  .length;
              final skipped = medLogs
                  .where((log) => log.action == MedicationAction.skipped)
                  .length;
              final total = medLogs.length;
              final adherence = total > 0 ? (taken / total * 100) : 0.0;

              return pw.TableRow(
                children: [
                  _buildTableCell(med.name, font),
                  _buildTableCell(taken.toString(), font),
                  _buildTableCell(skipped.toString(), font),
                  _buildTableCell('${adherence.toStringAsFixed(1)}%', font),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Construye una celda de tabla
  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: isHeader ? 12 : 10),
      ),
    );
  }

  /// Construye el footer
  pw.Widget _buildFooter(pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generado por MemoryMedic - Tu asistente de medicación',
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColors.grey600,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Obtiene el color según el porcentaje de adherencia
  PdfColor _getAdherenceColor(double percentage) {
    if (percentage >= 80) return PdfColors.green;
    if (percentage >= 60) return PdfColors.orange;
    return PdfColors.red;
  }

  /// Guarda el PDF en el dispositivo
  Future<File> _savePdf(pw.Document pdf) async {
    debugPrint('🟡 [_savePdf] Convirtiendo PDF a bytes...');
    final bytes = await pdf.save();
    debugPrint('🟡 [_savePdf] PDF convertido: ${bytes.length} bytes');

    debugPrint('🟡 [_savePdf] Obteniendo directorio de documentos...');
    final directory = await getApplicationDocumentsDirectory();
    debugPrint('🟡 [_savePdf] Directorio: ${directory.path}');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${directory.path}/MemoryMedic_Estadisticas_$timestamp.pdf',
    );
    debugPrint('🟡 [_savePdf] Ruta del archivo: ${file.path}');

    debugPrint('🟡 [_savePdf] Escribiendo bytes al archivo...');
    await file.writeAsBytes(bytes);
    debugPrint('🟡 [_savePdf] Archivo guardado exitosamente');

    return file;
  }

  /// Comparte el PDF usando el sistema de compartir nativo
  Future<void> sharePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  /// Abre el PDF para visualización
  Future<void> openPdf(File pdfFile) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await pdfFile.readAsBytes(),
    );
  }
}
