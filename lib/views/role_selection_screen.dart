/// Pantalla de Selección de Rol para MemoryMedic
/// Permite al usuario elegir si es Paciente o Cuidador
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  Future<void> _handleContinue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rol'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.updateUserRole(_selectedRole!);

    if (!mounted) return;

    if (!success && authViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
    // Si es exitoso, el AuthWrapper redirigirá automáticamente al Home
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Text(
                '¿Quién eres?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecciona tu rol para personalizar tu experiencia',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.gray400),
              ),
              const SizedBox(height: 48),

              // Tarjeta de Paciente
              _RoleCard(
                icon: Icons.person,
                title: 'Paciente',
                description: 'Soy la persona que toma los medicamentos',
                isSelected: _selectedRole == UserRole.patient,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.patient;
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Tarjeta de Cuidador
              _RoleCard(
                icon: Icons.favorite,
                title: 'Cuidador',
                description: 'Cuido a alguien que necesita tomar medicamentos',
                isSelected: _selectedRole == UserRole.caregiver,
                onTap: () {
                  setState(() {
                    _selectedRole = UserRole.caregiver;
                  });
                },
                isDark: isDark,
              ),
              const SizedBox(height: 48),

              // Botón de continuar
              ElevatedButton(
                onPressed: authViewModel.isLoading ? null : _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: authViewModel.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'CONTINUAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.secondary.withOpacity(0.1))
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primary : AppColors.secondary)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.primary : AppColors.secondary)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primary : AppColors.secondary)
                    : (isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 40,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.primary : AppColors.secondary),
              ),
            ),
            const SizedBox(width: 16),

            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),

            // Indicador de selección
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: isDark ? AppColors.primary : AppColors.secondary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
