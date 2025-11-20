import 'package:flutter/material.dart';
import '../services/statistics_service.dart';

/// Widget de gráfico de barras para adherencia diaria
class DailyAdherenceChart extends StatelessWidget {
  final List<DailyAdherence> dailyData;
  final double height;

  const DailyAdherenceChart({
    super.key,
    required this.dailyData,
    this.height = 128,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores para las barras
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = isDark
        ? theme.colorScheme.secondary
        : const Color(0xFFB2FFFB); // light-accent

    return SizedBox(
      height: height + 30, // +30 para las etiquetas
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final data = dailyData.firstWhere(
            (d) => d.weekday == index,
            orElse: () => DailyAdherence(
              weekday: index,
              percentage: 0,
              taken: 0,
              total: 0,
            ),
          );

          // Determinar color de la barra
          // Si la adherencia es >= 90%, usar color primario
          final barColor =
              data.percentage >= 90 ? primaryColor : secondaryColor;

          return _BarItem(
            label: data.weekdayName,
            percentage: data.percentage,
            height: height,
            color: barColor,
          );
        }),
      ),
    );
  }
}

/// Widget individual de barra
class _BarItem extends StatelessWidget {
  final String label;
  final double percentage;
  final double height;
  final Color color;

  const _BarItem({
    required this.label,
    required this.percentage,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Barra
        Container(
          width: 16,
          height: (height * percentage / 100).clamp(4.0, height),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Etiqueta
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

