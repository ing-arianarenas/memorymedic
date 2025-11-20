import 'dart:io';
import 'package:flutter/material.dart';
import '../models/medication.dart';

class MedicationReminderScreen extends StatelessWidget {
  final Medication medication;
  final VoidCallback? onTake;
  final VoidCallback? onSnooze;
  final VoidCallback? onSkip;

  const MedicationReminderScreen({
    super.key,
    required this.medication,
    this.onTake,
    this.onSnooze,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF121A1A) 
          : const Color(0xFFF7FDFD),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tarjeta principal con imagen flotante
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Tarjeta de contenido
                    Container(
                      margin: const EdgeInsets.only(top: 48),
                      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF2D3131) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título
                          Text(
                            'Hora de tu medicamento',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark 
                                  ? const Color(0xFF3BDDD5) 
                                  : const Color(0xFF2F6A67),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Nombre y dosis del medicamento
                          Text(
                            '${medication.name} - ${medication.dosage}',
                            style: TextStyle(
                              fontSize: 18,
                              color: isDark 
                                  ? const Color(0xFFE0E3E3).withOpacity(0.8)
                                  : const Color(0xFF1A1C1C).withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          
                          // Botón TOMAR
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                onTake?.call();
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3BDDD5),
                                foregroundColor: const Color(0xFF2F6A67),
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text(
                                'TOMAR',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Botones secundarios
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Botón Posponer
                              TextButton(
                                onPressed: () {
                                  onSnooze?.call();
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Recordatorio pospuesto. El próximo aplazamiento será progresivo (5→10→15 min)'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark 
                                      ? const Color(0xFF3BDDD5)
                                      : const Color(0xFF2F6A67),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Posponer',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              
                              // Botón Omitir
                              TextButton(
                                onPressed: () {
                                  onSkip?.call();
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: isDark 
                                      ? const Color(0xFFE0E3E3).withOpacity(0.6)
                                      : const Color(0xFF1A1C1C).withOpacity(0.6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Omitir',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Imagen del medicamento flotante
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          children: [
                            // Imagen circular
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark 
                                      ? const Color(0xFF2D3131)
                                      : Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: medication.imagePath != null
                                    ? Image.file(
                                        File(medication.imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildDefaultMedicationIcon(isDark);
                                        },
                                      )
                                    : _buildDefaultMedicationIcon(isDark),
                              ),
                            ),
                            
                            // Ícono de píldora
                            Positioned(
                              bottom: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? const Color(0xFF2F6A67)
                                      : const Color(0xFFB2FFFB),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.medication,
                                  color: isDark 
                                      ? const Color(0xFFB2FFFB)
                                      : const Color(0xFF2F6A67),
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultMedicationIcon(bool isDark) {
    return Container(
      color: isDark 
          ? const Color(0xFF2F6A67)
          : const Color(0xFFB2FFFB),
      child: Icon(
        Icons.medication,
        size: 48,
        color: isDark 
            ? const Color(0xFFB2FFFB)
            : const Color(0xFF2F6A67),
      ),
    );
  }
}

