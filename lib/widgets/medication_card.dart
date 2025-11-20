import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../config/app_theme.dart';

/// Widget de tarjeta para mostrar un medicamento
class MedicationCard extends StatelessWidget {
  final Medication medication;
  final ValueChanged<bool>? onToggle; // Opcional para cuidadores (solo lectura)
  final VoidCallback? onTap;

  const MedicationCard({
    super.key,
    required this.medication,
    this.onToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono del medicamento
              _buildIcon(isDark),
              const SizedBox(width: 16),

              // Información del medicamento
              Expanded(child: _buildInfo(context, isDark)),

              // Toggle switch
              _buildToggleSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el icono del medicamento
  Widget _buildIcon(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: medication.isActive ? AppColors.primary : AppColors.neutral,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Icon(
        medication.icon,
        color: medication.isActive
            ? AppColors.secondary
            : (isDark ? AppColors.gray400 : AppColors.gray500),
        size: 24,
      ),
    );
  }

  /// Construye la información del medicamento
  Widget _buildInfo(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          medication.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Próxima toma: ${medication.nextDoseTime}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.gray400 : AppColors.gray500,
          ),
        ),
      ],
    );
  }

  /// Construye el toggle switch personalizado
  Widget _buildToggleSwitch() {
    // Si onToggle es null (cuidadores), mostrar el toggle en modo solo lectura
    return GestureDetector(
      // Prevenir que el tap se propague al InkWell padre
      onTap: onToggle != null ? () {
        onToggle!(!medication.isActive);
      } : null,
      // Permitir que el tap se propague si onToggle es null
      behavior: onToggle != null ? HitTestBehavior.opaque : HitTestBehavior.translucent,
      child: Opacity(
        opacity: onToggle != null ? 1.0 : 0.5, // Menos opaco si es solo lectura
        child: Container(
          width: 48,
          height: 44, // Altura mínima para accesibilidad táctil
          alignment: Alignment.center,
          child: Container(
            width: 48,
            height: 24,
            decoration: BoxDecoration(
              color: medication.isActive
                  ? AppColors.secondary
                  : AppColors.neutral,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: medication.isActive
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
