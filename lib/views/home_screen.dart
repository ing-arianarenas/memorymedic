import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/statistics_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/medication_card.dart';
import '../config/app_theme.dart';
import '../models/medication.dart';
import 'add_medication_screen.dart';
import 'statistics_screen.dart';
import 'patient_monitoring_screen.dart';
import 'patient_link_code_screen.dart';
import 'caregiver_link_screen.dart';

/// Pantalla principal - Lista de medicamentos
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              _buildHeader(context, isDark),
              const SizedBox(height: 24),

              // Lista de medicamentos
              Expanded(child: _buildMedicationList(context)),
            ],
          ),
        ),
      ),

      // Botón flotante para agregar medicamento
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /// Construye el header con título y avatar
  Widget _buildHeader(BuildContext context, bool isDark) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Título
        Text(
          'MEDICAMENTOS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.primary : AppColors.secondary,
            letterSpacing: 0.5,
          ),
        ),

        // Botones de acción
        Row(
          children: [
            // Botón de vinculación (para pacientes sin cuidador o cuidadores sin paciente)
            if (currentUser != null) ...[
              if (currentUser.isPatient) ...[
                // Paciente: mostrar botón para generar código
                IconButton(
                  onPressed: () => _navigateToPatientLinkCode(context),
                  icon: const Icon(Icons.qr_code_2),
                  iconSize: 28,
                  color: isDark ? AppColors.primary : AppColors.secondary,
                  tooltip: 'Código de Vinculación',
                ),
                const SizedBox(width: 8),
              ] else if (currentUser.isCaregiver &&
                  currentUser.patientId == null) ...[
                // Cuidador sin paciente: mostrar botón para vincular
                IconButton(
                  onPressed: () => _navigateToCaregiverLink(context),
                  icon: const Icon(Icons.link),
                  iconSize: 28,
                  color: isDark ? AppColors.primary : AppColors.secondary,
                  tooltip: 'Vincular con Paciente',
                ),
                const SizedBox(width: 8),
              ] else if (currentUser.isCaregiver &&
                  currentUser.patientId != null) ...[
                // Cuidador con paciente: mostrar botón de monitoreo
                IconButton(
                  onPressed: () => _navigateToPatientMonitoring(
                    context,
                    currentUser.patientId!,
                  ),
                  icon: const Icon(Icons.monitor_heart),
                  iconSize: 28,
                  color: isDark ? AppColors.primary : AppColors.secondary,
                  tooltip: 'Monitorear Paciente',
                ),
                const SizedBox(width: 8),
              ],
            ],
            // Botón de estadísticas
            IconButton(
              onPressed: () => _navigateToStatistics(context),
              icon: const Icon(Icons.bar_chart),
              iconSize: 28,
              color: isDark ? AppColors.primary : AppColors.secondary,
            ),
            const SizedBox(width: 8),
            // Avatar con dropdown
            _buildProfileButton(context, isDark),
          ],
        ),
      ],
    );
  }

  /// Navega a la pantalla de monitoreo de paciente
  void _navigateToPatientMonitoring(BuildContext context, String patientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientMonitoringScreen(patientId: patientId),
      ),
    );
  }

  /// Navega a la pantalla de código de vinculación (paciente)
  void _navigateToPatientLinkCode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientLinkCodeScreen()),
    );
  }

  /// Navega a la pantalla de vinculación (cuidador)
  void _navigateToCaregiverLink(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaregiverLinkScreen()),
    );
  }

  /// Navega a la pantalla de estadísticas
  void _navigateToStatistics(BuildContext context) {
    final homeViewModel = context.read<HomeViewModel>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: homeViewModel),
            ChangeNotifierProvider(
              create: (_) =>
                  StatisticsViewModel(medications: homeViewModel.medications),
            ),
          ],
          child: const StatisticsScreen(),
        ),
      ),
    );
  }

  /// Construye el botón de perfil con avatar
  Widget _buildProfileButton(BuildContext context, bool isDark) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'logout') {
          // Mostrar diálogo de confirmación
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cerrar sesión'),
              content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          );

          if (confirm == true && context.mounted) {
            await authViewModel.signOut();
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser?.displayName ?? 'Usuario',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                currentUser?.email ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
              if (currentUser?.role != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    currentUser!.roleName,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.primary : AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20),
              SizedBox(width: 12),
              Text('Cerrar sesión'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circular
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.neutral,
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    )
                  : null,
            ),
            const SizedBox(width: 8),

            // Icono de dropdown
            Icon(
              Icons.arrow_drop_down,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la lista de medicamentos
  Widget _buildMedicationList(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.medications.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          itemCount: viewModel.medications.length,
          itemBuilder: (context, index) {
            final medication = viewModel.medications[index];
            final authViewModel = context.watch<AuthViewModel>();
            final currentUser = authViewModel.currentUser;
            final isCaregiver = currentUser?.isCaregiver ?? false;

            return MedicationCard(
              medication: medication,
              onToggle: isCaregiver
                  ? null // Los cuidadores no pueden modificar medicamentos
                  : (value) {
                      viewModel.toggleMedicationStatus(medication.id);
                    },
              onTap: isCaregiver
                  ? null // Los cuidadores no pueden editar medicamentos (solo lectura)
                  : () async {
                      // Navegar a la pantalla de editar medicamento
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddMedicationScreen(medication: medication),
                        ),
                      );

                      // Si se retornó un medicamento editado, actualizarlo
                      if (result != null && result is Medication && context.mounted) {
                        try {
                          await viewModel.updateMedication(result);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${result.name} actualizado correctamente',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.secondary,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al actualizar medicamento: $e'),
                                duration: const Duration(seconds: 3),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
            );
          },
        );
      },
    );
  }

  /// Construye el estado vacío cuando no hay medicamentos
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: isDark ? AppColors.gray400 : AppColors.gray500,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay medicamentos registrados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.gray400 : AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar uno',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// Construye el botón flotante de acción
  Widget _buildFloatingActionButton(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    
    // Los cuidadores no pueden agregar medicamentos (solo lectura)
    final isCaregiver = currentUser?.isCaregiver ?? false;
    
    if (isCaregiver) {
      return const SizedBox.shrink(); // No mostrar el botón para cuidadores
    }

    return FloatingActionButton(
      onPressed: () async {
        // Navegar a la pantalla de agregar medicamento
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddMedicationScreen()),
        );

        // Si se retornó un medicamento, agregarlo a la lista
        if (result != null && result is Medication && context.mounted) {
          final viewModel = Provider.of<HomeViewModel>(context, listen: false);

          try {
            await viewModel.addMedication(result);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${result.name} agregado correctamente'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.secondary,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al guardar medicamento: $e'),
                  duration: const Duration(seconds: 3),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      child: const Icon(Icons.add, size: 28),
    );
  }
}
