import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../config/app_theme.dart';
import '../widgets/form_card.dart';
import '../models/medication.dart';

/// Pantalla para agregar un nuevo medicamento
class AddMedicationScreen extends StatefulWidget {
  final Medication? medication; // Para edición

  const AddMedicationScreen({super.key, this.medication});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  // Controladores de texto
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _quantityController = TextEditingController();

  // Valores del formulario
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isAM = true; // Para controlar AM/PM
  String _selectedFrequency = 'Cada 6 horas';
  String _selectedDoseUnit = 'mg';
  String _selectedSound = 'Predeterminado';
  bool _canPostpone = true;
  int _postponeMinutes = 5;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _imagePath;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // Opciones
  final List<String> _frequencies = [
    'Cada 6 horas',
    'Cada 8 horas',
    'Cada 12 horas',
    'Cada 24 horas',
  ];

  final List<String> _doseUnits = ['mg', 'ml', 'cápsula(s)', 'tableta(s)', 'gota(s)'];

  final List<String> _sounds = ['Predeterminado', 'Alarma suave', 'Campanas'];

  final List<int> _postponeOptions = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    // Si estamos editando, cargar los datos del medicamento
    if (widget.medication != null) {
      _loadMedicationData();
    }
  }

  /// Carga los datos del medicamento para edición
  void _loadMedicationData() {
    final med = widget.medication!;
    _nameController.text = med.name;
    _doseController.text = med.dose.toString();
    _quantityController.text = med.totalQuantity?.toString() ?? '';
    _selectedTime = med.scheduleTime;
    _isAM = med.scheduleTime.hour < 12; // Determinar AM/PM basado en la hora
    _selectedFrequency = med.frequency;
    _selectedDoseUnit = med.doseUnit;
    _selectedSound = med.soundType;
    _canPostpone = med.canPostpone;
    _postponeMinutes = med.postponeMinutes;
    _startDate = med.startDate;
    _endDate = med.endDate;
    _imagePath = med.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Solicita permisos de cámara
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Solicita permisos de galería
  Future<bool> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await Permission.photos.status;
      if (androidInfo.isDenied) {
        final status = await Permission.photos.request();
        return status.isGranted;
      }
      return androidInfo.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return true;
  }

  /// Muestra opciones para seleccionar imagen
  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seleccionar imagen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imagePath = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Selecciona imagen desde cámara o galería
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Solicitar permisos
      bool hasPermission = false;
      if (source == ImageSource.camera) {
        hasPermission = await _requestCameraPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se requiere permiso de cámara'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      } else {
        hasPermission = await _requestGalleryPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Se requiere permiso de galería'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      // Seleccionar imagen
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNameField(),
                    _buildImageField(),
                    _buildTimeField(),
                    _buildFrequencyField(),
                    _buildDoseField(),
                    _buildQuantityField(),
                    _buildDurationField(),
                    _buildSoundField(),
                    _buildPostponeField(),
                  ],
                ),
              ),
            ),

            // Botones de acción
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Construye el header con botón de retroceso y título
  Widget _buildHeader(BuildContext context, bool isDark) {
    final isEditing = widget.medication != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new),
            color: isDark ? AppColors.textDark : AppColors.textLight,
            iconSize: 24,
          ),
          const SizedBox(width: 8),
          Text(
            isEditing ? 'Editar medicamento' : 'Agregar medicamento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Campo de nombre
  Widget _buildNameField() {
    return FormCard(
      label: 'Nombre:',
      child: CustomTextField(
        controller: _nameController,
        hintText: 'Ej: Ibuprofeno',
      ),
    );
  }

  /// Campo de imagen
  Widget _buildImageField() {
    return FormCard(
      label: 'Imagen:',
      child: InkWell(
        onTap: _showImageSourceOptions,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.neutral,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Imagen seleccionada
                      Image.file(
                        File(_imagePath!),
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                      // Overlay con icono de editar
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 32,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seleccionar o tomar foto',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Formatea la hora en formato 12 horas (AM/PM)
  String _formatTime12Hour(TimeOfDay time) {
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    int displayHour = time.hourOfPeriod;
    if (displayHour == 0) displayHour = 12;
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Campo de horario
  Widget _buildTimeField() {
    return FormCard(
      label: 'Horario:',
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              // Crear hora inicial considerando AM/PM
              int hour = _selectedTime.hourOfPeriod;
              if (!_isAM && hour == 0) hour = 12;
              final TimeOfDay initialTime = TimeOfDay(
                hour: _isAM ? hour : hour + 12,
                minute: _selectedTime.minute,
              );
              
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
                helpText: 'Selecciona la hora',
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      // Forzar formato 12 horas en el TimePicker
                      alwaysUse24HourFormat: false,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: AppColors.secondary,
                          surface: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.cardDark
                              : AppColors.cardLight,
                          onSurface: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textDark
                              : AppColors.textLight,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                },
              );
              
              if (picked != null) {
                setState(() {
                  _selectedTime = picked;
                  _isAM = picked.hour < 12;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.neutral),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime12Hour(_selectedTime),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textDark
                          : AppColors.textLight,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Icon(Icons.access_time, color: AppColors.gray500),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón AM
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isAM = true;
                      // Ajustar hora si es necesario (convertir PM a AM)
                      if (_selectedTime.hour > 12) {
                        // Hora 13-23 → convertir a 1-11 AM
                        _selectedTime = TimeOfDay(
                          hour: _selectedTime.hour - 12,
                          minute: _selectedTime.minute,
                        );
                      } else if (_selectedTime.hour == 12) {
                        // Hora 12 → convertir a 12 AM (medianoche)
                        _selectedTime = TimeOfDay(
                          hour: 0,
                          minute: _selectedTime.minute,
                        );
                      }
                      // Si ya es 0-11, no cambiar nada
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isAM ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isAM ? AppColors.primary : AppColors.neutral,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'AM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isAM
                            ? AppColors.secondary
                            : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textDark
                                : AppColors.textLight),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón PM
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isAM = false;
                      // Ajustar hora si es necesario (convertir AM a PM)
                      if (_selectedTime.hour == 0) {
                        // Hora 0 (medianoche) → convertir a 12 PM (mediodía)
                        _selectedTime = TimeOfDay(
                          hour: 12,
                          minute: _selectedTime.minute,
                        );
                      } else if (_selectedTime.hour < 12) {
                        // Hora 1-11 → convertir a 13-23 PM
                        _selectedTime = TimeOfDay(
                          hour: _selectedTime.hour + 12,
                          minute: _selectedTime.minute,
                        );
                      }
                      // Si ya es 12-23, no cambiar nada
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isAM ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isAM ? AppColors.primary : AppColors.neutral,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      'PM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: !_isAM
                            ? AppColors.secondary
                            : (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textDark
                                : AppColors.textLight),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Campo de frecuencia
  Widget _buildFrequencyField() {
    return FormCard(
      label: 'Frecuencia:',
      child: CustomDropdown<String>(
        value: _selectedFrequency,
        items: _frequencies,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedFrequency = value;
            });
          }
        },
      ),
    );
  }

  /// Campo de dosis
  Widget _buildDoseField() {
    return FormCard(
      label: 'Dosis:',
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomTextField(
              controller: _doseController,
              keyboardType: TextInputType.number,
              hintText: 'Cantidad',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomDropdown<String>(
              value: _selectedDoseUnit,
              items: _doseUnits,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedDoseUnit = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Campo de cantidad total
  Widget _buildQuantityField() {
    return FormCard(
      label: 'Cantidad total:',
      child: CustomTextField(
        controller: _quantityController,
        keyboardType: TextInputType.number,
        hintText: 'Para seguimiento de recargas',
      ),
    );
  }

  /// Campo de duración
  Widget _buildDurationField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FormCard(
      label: 'Duración (opcional):',
      child: Row(
        children: [
          Expanded(
            child: _buildDateField(
              context,
              _startDate,
              'Inicio',
              (date) => setState(() => _startDate = date),
              isDark,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('-'),
          ),
          Expanded(
            child: _buildDateField(
              context,
              _endDate,
              'Fin',
              (date) => setState(() => _endDate = date),
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    DateTime? date,
    String hint,
    ValueChanged<DateTime?> onChanged,
    bool isDark,
  ) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral),
        ),
        child: Text(
          date != null ? '${date.day}/${date.month}/${date.year}' : hint,
          style: TextStyle(
            color: date != null
                ? (isDark ? AppColors.textDark : AppColors.textLight)
                : AppColors.gray500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// Campo de sonido
  Widget _buildSoundField() {
    return FormCard(
      label: 'Sonido:',
      child: CustomDropdown<String>(
        value: _selectedSound,
        items: _sounds,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedSound = value;
            });
          }
        },
      ),
    );
  }

  /// Campo de posponer
  Widget _buildPostponeField() {
    return FormCard(
      label: '',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Posponer:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              CustomToggle(
                value: _canPostpone,
                onChanged: (value) {
                  setState(() {
                    _canPostpone = value;
                  });
                },
              ),
            ],
          ),
          if (_canPostpone) ...[
            const SizedBox(height: 12),
            CustomDropdown<int>(
              value: _postponeMinutes,
              items: _postponeOptions,
              itemLabel: (value) => '$value minutos',
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _postponeMinutes = value;
                  });
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Botones de guardar y cancelar
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Botón Guardar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'GUARDAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botón Cancelar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene el icono según la unidad de dosis
  IconData _getIconForDoseUnit(String doseUnit) {
    switch (doseUnit.toLowerCase()) {
      case 'mg':
        return Icons.inventory_2; // Frasco en polvo
      case 'cápsula(s)':
        return Icons.medication_liquid; // Cápsula (icono similar)
      case 'tableta(s)':
        return Icons.medication; // Tableta
      case 'ml':
        return Icons.science; // Frasco y cuchara
      case 'gota(s)':
        return Icons.water_drop; // Gotero
      default:
        return Icons.medication;
    }
  }

  /// Guarda el medicamento
  void _saveMedication() {
    // Validar campos
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el nombre del medicamento'),
        ),
      );
      return;
    }

    if (_doseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la dosis')),
      );
      return;
    }

    // Asegurar que la hora esté correcta con AM/PM
    TimeOfDay finalTime = _selectedTime;
    if (!_isAM && _selectedTime.hour < 12) {
      // Convertir a PM
      final hour = _selectedTime.hour == 0 ? 12 : _selectedTime.hour;
      finalTime = TimeOfDay(hour: hour + 12, minute: _selectedTime.minute);
    } else if (_isAM && _selectedTime.hour >= 12) {
      // Convertir a AM
      final hour = _selectedTime.hour - 12;
      finalTime = TimeOfDay(hour: hour == 0 ? 12 : hour, minute: _selectedTime.minute);
    }

    // Crear medicamento con icono según unidad
    final medication = Medication(
      id: widget.medication?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      imagePath: _imagePath,
      scheduleTime: finalTime,
      frequency: _selectedFrequency,
      dose: double.tryParse(_doseController.text) ?? 0,
      doseUnit: _selectedDoseUnit,
      totalQuantity: int.tryParse(_quantityController.text),
      startDate: _startDate,
      endDate: _endDate,
      soundType: _selectedSound,
      canPostpone: _canPostpone,
      postponeMinutes: _postponeMinutes,
      isActive: true,
      icon: _getIconForDoseUnit(_selectedDoseUnit),
    );

    // Retornar el medicamento a la pantalla anterior
    Navigator.pop(context, medication);
  }
}
