import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/features/metrics/application/metrics_cubit.dart';
import 'package:IAEntrenar/features/metrics/application/metrics_state.dart';
import 'package:IAEntrenar/features/metrics/domain/entities/capacity_type.dart';
import 'package:IAEntrenar/features/metrics/domain/entities/fitness_metric_record.dart';
import 'package:IAEntrenar/features/metrics/domain/entities/metric_unit.dart';
import 'package:IAEntrenar/features/workout/application/exercise_cubit.dart';
import 'package:IAEntrenar/features/workout/application/exercise_state.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';
import 'package:IAEntrenar/models/exercise.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RMCalculatorScreen extends StatefulWidget {
  const RMCalculatorScreen({super.key});

  @override
  State<RMCalculatorScreen> createState() => _RMCalculatorScreenState();
}

class _RMCalculatorScreenState extends State<RMCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _exerciseNameController = TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();
  final TextEditingController _metricValueController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  String _filterType =
      'date_desc'; // Options: date_asc, date_desc, growth_asc, growth_desc
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  /// Ejercicio de métrica seleccionado (resistencia, velocidad, movilidad, cardio). Null = se muestra RM.
  String? _metricExerciseKey;
  String? _metricDisplayName;
  CapacityType? _metricCapacityType;
  MetricUnit? _metricUnit;

  /// Unidad elegida al actualizar (solo tiempo: seg/min/h). Null = usar _metricUnit.
  MetricUnit? _metricUpdateUnit;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserMetricsIfNeeded();
      final selectedExercise =
          context.read<ExerciseCubit>().state.selectedExercise;
      if (selectedExercise != null && _metricExerciseKey == null) {
        _exerciseNameController.text = selectedExercise.name;
        _maxWeightController.text = selectedExercise.maxWeight.toString();
      }
    });
  }

  void _loadUserMetricsIfNeeded() {
    final userId = context.read<AuthBloc>().state.profile?.id;
    if (userId != null && userId.isNotEmpty) {
      context.read<MetricsCubit>().loadUserMetrics(userId);
    }
  }

  /// Un ejercicio por cada (exerciseKey, capacityType) distinto; excluye strength (RM está en ExerciseCubit).
  List<FitnessMetricRecord> _distinctMetricExercises(
      List<FitnessMetricRecord> metrics) {
    final seen = <String>{};
    final out = <FitnessMetricRecord>[];
    for (final m in metrics) {
      if (m.capacityType == CapacityType.strength) continue;
      final k = '${m.exerciseKey}:${m.capacityType.name}';
      if (!seen.contains(k)) {
        seen.add(k);
        out.add(m);
      }
    }
    return out;
  }

  /// Progreso de una métrica (valor y fecha), filtrado por rango de fechas y ordenado.
  List<({double value, DateTime date})> _metricProgressList(
    List<FitnessMetricRecord> metrics,
    String exerciseKey,
    CapacityType capacityType,
  ) {
    final list = metrics
        .where((m) =>
            m.exerciseKey == exerciseKey && m.capacityType == capacityType)
        .map((m) => (value: m.value, date: m.recordedAt))
        .where((e) => !e.date.isBefore(_startDate) && !e.date.isAfter(_endDate))
        .toList();
    list.sort((a, b) => _filterType.contains('asc')
        ? a.date.compareTo(b.date)
        : b.date.compareTo(a.date));
    return list;
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _maxWeightController.dispose();
    _metricValueController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    MetricUnit selectedUnit = MetricUnit.kg;
    bool unitLoaded = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!unitLoaded) {
            unitLoaded = true;
            SharedPreferences.getInstance().then((prefs) {
              final saved = prefs.getString('settings_default_weight_unit_v1');
              final parsed = MetricUnit.fromFirestore(saved);
              if (parsed != null && parsed.isWeight) {
                setDialogState(() => selectedUnit = parsed);
              }
            });
          }
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Añadir Ejercicio (RM)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Ejercicio',
                      prefixIcon: Icon(
                        Icons.fitness_center,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Peso Máximo (RM)',
                      suffixText: selectedUnit == MetricUnit.kg ? 'kg' : 'lb',
                      prefixIcon: Icon(
                        Icons.monitor_weight,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Unidad: ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SegmentedButton<MetricUnit>(
                        segments: const [
                          ButtonSegment(
                              value: MetricUnit.kg,
                              label: Text('kg'),
                              icon: Icon(Icons.straighten, size: 18)),
                          ButtonSegment(
                              value: MetricUnit.lb,
                              label: Text('lb'),
                              icon: Icon(Icons.monitor_weight_outlined,
                                  size: 18)),
                        ],
                        selected: {selectedUnit},
                        onSelectionChanged: (Set<MetricUnit> s) {
                          setDialogState(() => selectedUnit = s.first);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancelar',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final name = nameController.text.trim();
                  final weightText = weightController.text.trim();
                  if (name.isEmpty || weightText.isEmpty) {
                    AppAlerts.showWarning(
                        context, 'Por favor completa todos los campos');
                    return;
                  }
                  try {
                    final value = double.parse(weightText);
                    final weightKg = selectedUnit == MetricUnit.lb
                        ? context.read<MetricsCubit>().convertWeight(
                              value: value,
                              fromUnit: MetricUnit.lb,
                              toUnit: MetricUnit.kg,
                            )
                        : value;
                    context.read<ExerciseCubit>().addExercise(name, weightKg);
                    try {
                      final savedToCloud = await _saveStrengthMetricToFirebase(
                          context, name, value,
                          unit: selectedUnit);
                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      _exerciseNameController.text = name;
                      _maxWeightController.text = value.toString();
                      AppAlerts.showSuccessAtBottom(
                        context,
                        savedToCloud
                            ? 'Guardado localmente y en la nube'
                            : 'Guardado localmente. Inicia sesión para sincronizar en la nube',
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      Navigator.pop(dialogContext);
                      _exerciseNameController.text = name;
                      _maxWeightController.text = value.toString();
                      AppAlerts.showError(context,
                          'Guardado localmente. Error al sincronizar en la nube: $e');
                    }
                  } catch (e) {
                    AppAlerts.showWarning(
                        context, 'Por favor ingresa un número válido');
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Genera una clave estable para Firestore a partir del nombre mostrado.
  static String _exerciseKeyFromName(String displayName) {
    return displayName
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Guarda el RM de fuerza en Firestore. Devuelve true si se guardó, false si no hay usuario.
  /// Lanza si hay error de red/Firestore.
  Future<bool> _saveStrengthMetricToFirebase(
    BuildContext context,
    String exerciseDisplayName,
    double value, {
    MetricUnit unit = MetricUnit.kg,
  }) async {
    final userId = context.read<AuthBloc>().state.profile?.id;
    if (userId == null || userId.isEmpty) return false;
    final exerciseKey = _exerciseKeyFromName(exerciseDisplayName);
    if (exerciseKey.isEmpty) return false;
    await context.read<MetricsCubit>().saveMetric(
          userId: userId,
          capacityType: CapacityType.strength,
          exerciseKey: exerciseKey,
          exerciseDisplayName: exerciseDisplayName,
          value: value,
          unit: unit,
        );
    return true;
  }

  /// Unidades disponibles según el tipo de capacidad.
  static List<MetricUnit> _unitsForCapacity(CapacityType type) {
    switch (type) {
      case CapacityType.strength:
        return [MetricUnit.kg, MetricUnit.lb];
      case CapacityType.endurance:
        return [MetricUnit.reps];
      case CapacityType.speed:
      case CapacityType.cardio:
        return [MetricUnit.seconds, MetricUnit.minutes, MetricUnit.hours];
      case CapacityType.mobility:
        return [MetricUnit.score];
    }
  }

  static String _unitLabel(MetricUnit u) {
    switch (u) {
      case MetricUnit.kg:
        return 'kg';
      case MetricUnit.lb:
        return 'lb';
      case MetricUnit.reps:
        return 'repeticiones';
      case MetricUnit.seconds:
        return 'segundos';
      case MetricUnit.minutes:
        return 'minutos';
      case MetricUnit.hours:
        return 'horas';
      case MetricUnit.score:
        return 'puntuación';
    }
  }

  /// Bottom sheet para registrar una métrica de resistencia, velocidad, movilidad o cardio.
  void _showAddOtherMetricSheet() {
    final userId = context.read<AuthBloc>().state.profile?.id;
    if (userId == null || userId.isEmpty) {
      AppAlerts.showInfo(
          context, 'Inicia sesión para guardar métricas en la nube');
      return;
    }

    CapacityType selectedType = CapacityType.endurance;
    final nameController = TextEditingController();
    final valueController = TextEditingController();
    MetricUnit selectedUnit = MetricUnit.reps;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final units = _unitsForCapacity(selectedType);
          if (!units.contains(selectedUnit)) {
            selectedUnit = units.first;
          }
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Añadir métrica de capacidad',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registra resistencia, velocidad, movilidad o cardio. Se guarda en la nube y alimenta tu perfil.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<CapacityType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de capacidad',
                      border: OutlineInputBorder(),
                    ),
                    items: CapacityType.values
                        .where((t) => t != CapacityType.strength)
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayName),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setSheetState(() {
                          selectedType = v;
                          selectedUnit = _unitsForCapacity(v).first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Ejercicio o prueba (ej: Push-ups, 5K run)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Valor',
                      suffixText: _unitLabel(selectedUnit),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MetricUnit>(
                    value: selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                      border: OutlineInputBorder(),
                    ),
                    items: units
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(_unitLabel(u)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedUnit = v);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final valueText = valueController.text.trim();
                            if (name.isEmpty || valueText.isEmpty) {
                              AppAlerts.showWarning(
                                  context, 'Completa nombre y valor');
                              return;
                            }
                            try {
                              final value = double.parse(valueText);
                              final key = _exerciseKeyFromName(name);
                              if (key.isEmpty) {
                                AppAlerts.showWarning(
                                    context, 'Nombre no válido para clave');
                                return;
                              }
                              context.read<MetricsCubit>().saveMetric(
                                    userId: userId,
                                    capacityType: selectedType,
                                    exerciseKey: key,
                                    exerciseDisplayName: name,
                                    value: value,
                                    unit: selectedUnit,
                                  );
                              Navigator.pop(sheetContext);
                              AppAlerts.showSuccess(
                                  context, 'Métrica guardada');
                            } catch (e) {
                              AppAlerts.showError(
                                  context, 'Valor no válido: $e');
                            }
                          },
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDateRangeDialog() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    ).then((range) {
      if (range != null) {
        setState(() {
          _startDate = range.start;
          _endDate = range.end;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calculadora RM',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Añadir otra métrica (resistencia, cardio…)',
            color: theme.colorScheme.primary,
            onPressed: _showAddOtherMetricSheet,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: theme.colorScheme.primary,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => _buildFilterOptions(),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: BlocBuilder<MetricsCubit, MetricsState>(
          buildWhen: (p, n) => p.metrics != n.metrics,
          builder: (context, metricsState) {
            return BlocBuilder<ExerciseCubit, ExerciseState>(
              builder: (context, state) {
                final selectedExercise = state.selectedExercise;
                final metricExercises =
                    _distinctMetricExercises(metricsState.metrics);
                final hasStrength = state.exercises.isNotEmpty;
                final hasMetricSelected = _metricExerciseKey != null;

                if (!hasStrength && metricExercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay ejercicios disponibles',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddExerciseDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir Ejercicio'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (hasMetricSelected) {
                  final progressList = _metricProgressList(metricsState.metrics,
                      _metricExerciseKey!, _metricCapacityType!);
                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.03),
                              theme.colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildExerciseSelector(state, metricExercises),
                                const SizedBox(height: 24),
                                _buildMetricCurrentInfo(),
                                const SizedBox(height: 24),
                                _buildProgressChartForMetric(progressList),
                                const SizedBox(height: 24),
                                _buildMetricTable(progressList),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (selectedExercise == null) {
                  if (state.exercises.isNotEmpty) {
                    context
                        .read<ExerciseCubit>()
                        .selectExercise(state.exercises.first.id);
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Solo métricas: mostrar selector y mensaje hasta que el usuario elija
                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.03),
                              theme.colorScheme.surface,
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildExerciseSelector(state, metricExercises),
                                const SizedBox(height: 24),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      'Selecciona un ejercicio del desplegable para ver progreso y tabla',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final progressData =
                    context.read<ExerciseCubit>().getProgressForExercise(
                          selectedExercise.id,
                          ascending: _filterType.contains('asc'),
                        );
                final percentages = context
                    .read<ExerciseCubit>()
                    .calculateRMPercentages(selectedExercise.maxWeight);

                return Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.03),
                            theme.colorScheme.surface,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                        left: MediaQuery.of(context).padding.left,
                        right: MediaQuery.of(context).padding.right,
                        bottom: MediaQuery.of(context).padding.bottom,
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExerciseSelector(state, metricExercises),
                              const SizedBox(height: 24),
                              _buildCurrentRMInfo(selectedExercise),
                              const SizedBox(height: 24),
                              _buildProgressChart(progressData),
                              const SizedBox(height: 24),
                              _buildPercentagesTable(percentages),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: FloatingActionButton(
          onPressed: _showAddExerciseDialog,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  String _currentDropdownLabel(
      ExerciseState state, List<FitnessMetricRecord> metricExercises) {
    if (_metricExerciseKey != null &&
        _metricDisplayName != null &&
        _metricCapacityType != null) {
      return '$_metricDisplayName (${_metricCapacityType!.displayName})';
    }
    final e = state.selectedExercise;
    if (e != null) return '${e.name} (RM)';
    if (state.exercises.isNotEmpty) return '${state.exercises.first.name} (RM)';
    if (metricExercises.isNotEmpty) {
      final m = metricExercises.first;
      return '${m.exerciseDisplayName} (${m.capacityType.displayName})';
    }
    return 'Selecciona un ejercicio';
  }

  Widget _buildExerciseSelector(
      ExerciseState state, List<FitnessMetricRecord> metricExercises) {
    final theme = Theme.of(context);
    final exercises = state.exercises;

    final labels = <String>[
      ...exercises.map((e) => '${e.name} (RM)'),
      ...metricExercises.map(
          (m) => '${m.exerciseDisplayName} (${m.capacityType.displayName})'),
    ];
    if (labels.isEmpty) labels.add('Selecciona un ejercicio');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionar Ejercicio',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          CustomDropdown<String>(
            hintText: 'Selecciona un ejercicio',
            items: labels,
            initialItem: _currentDropdownLabel(state, metricExercises),
            decoration: CustomDropdownDecoration(
              closedFillColor: theme.colorScheme.surface,
              expandedFillColor: theme.colorScheme.surface,
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorderRadius: BorderRadius.circular(12),
              headerStyle: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
              listItemStyle: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
            onChanged: (String? selectedLabel) {
              if (selectedLabel == null) return;
              final rmMatch =
                  exercises.where((e) => '${e.name} (RM)' == selectedLabel);
              if (rmMatch.isNotEmpty) {
                setState(() {
                  _metricExerciseKey = null;
                  _metricDisplayName = null;
                  _metricCapacityType = null;
                  _metricUnit = null;
                  _metricUpdateUnit = null;
                });
                context.read<ExerciseCubit>().selectExercise(rmMatch.first.id);
                _exerciseNameController.text = rmMatch.first.name;
                _maxWeightController.text = rmMatch.first.maxWeight.toString();
                return;
              }
              final metricMatch = metricExercises.where((m) =>
                  '${m.exerciseDisplayName} (${m.capacityType.displayName})' ==
                  selectedLabel);
              if (metricMatch.isNotEmpty) {
                final m = metricMatch.first;
                final metrics = context.read<MetricsCubit>().state.metrics;
                final forExercise = metrics
                    .where((e) =>
                        e.exerciseKey == m.exerciseKey &&
                        e.capacityType == m.capacityType)
                    .toList();
                forExercise
                    .sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
                final latestValue =
                    forExercise.isEmpty ? m.value : forExercise.first.value;
                setState(() {
                  _metricExerciseKey = m.exerciseKey;
                  _metricDisplayName = m.exerciseDisplayName;
                  _metricCapacityType = m.capacityType;
                  _metricUnit = m.unit;
                  final isTime = m.capacityType == CapacityType.speed ||
                      m.capacityType == CapacityType.cardio;
                  _metricUpdateUnit = isTime ? m.unit : null;
                  _metricValueController.text = latestValue
                      .toStringAsFixed(m.unit == MetricUnit.score ? 1 : 0);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  static bool _isTimeUnit(MetricUnit u) =>
      u == MetricUnit.seconds ||
      u == MetricUnit.minutes ||
      u == MetricUnit.hours;

  /// Convierte valor almacenado (segundos) a la unidad de visualización para tiempo.
  double _timeValueToDisplayUnit(
      double valueInSeconds, MetricUnit displayUnit) {
    switch (displayUnit) {
      case MetricUnit.seconds:
        return valueInSeconds;
      case MetricUnit.minutes:
        return valueInSeconds / 60;
      case MetricUnit.hours:
        return valueInSeconds / 3600;
      default:
        return valueInSeconds;
    }
  }

  /// Decimales para mostrar según unidad (tiempo: min/h con 1, seg con 0; score 1).
  int _displayDecimals(MetricUnit? u) {
    if (u == MetricUnit.score) return 1;
    if (u == MetricUnit.minutes || u == MetricUnit.hours) return 1;
    return 0;
  }

  Widget _buildMetricCurrentInfo() {
    final theme = Theme.of(context);
    final isTimeMetric = _metricCapacityType == CapacityType.speed ||
        _metricCapacityType == CapacityType.cardio;
    final updateUnit = _metricUpdateUnit ?? _metricUnit;
    final updateUnitLabel = updateUnit != null ? _unitLabel(updateUnit) : '';
    final latest = _metricProgressList(
      context.read<MetricsCubit>().state.metrics,
      _metricExerciseKey!,
      _metricCapacityType!,
    );
    final bestRaw = latest.isEmpty
        ? 0.0
        : latest.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final lastValueRaw = latest.isEmpty ? 0.0 : latest.first.value;
    // Para tiempo, mostrar en la unidad elegida; si no, valor crudo.
    final best = isTimeMetric && updateUnit != null && _isTimeUnit(updateUnit)
        ? _timeValueToDisplayUnit(bestRaw, updateUnit)
        : bestRaw;
    final lastValue =
        isTimeMetric && updateUnit != null && _isTimeUnit(updateUnit)
            ? _timeValueToDisplayUnit(lastValueRaw, updateUnit)
            : lastValueRaw;
    final displayLabel =
        isTimeMetric && updateUnit != null && _isTimeUnit(updateUnit)
            ? updateUnitLabel
            : (_metricUnit != null ? _unitLabel(_metricUnit!) : '');
    final decimals = _displayDecimals(updateUnit ?? _metricUnit);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_metricCapacityType?.displayName ?? ''} - Marca actual',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _metricDisplayName ?? '',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mejor: ${best.toStringAsFixed(decimals)} $displayLabel',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    Text(
                      lastValue.toStringAsFixed(decimals),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    Text(
                      displayLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isTimeMetric && updateUnit != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<MetricUnit>(
                value: updateUnit,
                decoration: const InputDecoration(
                  labelText: 'Unidad del valor',
                  border: OutlineInputBorder(),
                ),
                items: [
                  MetricUnit.seconds,
                  MetricUnit.minutes,
                  MetricUnit.hours,
                ]
                    .map((u) => DropdownMenuItem<MetricUnit>(
                          value: u,
                          child: Text(_unitLabel(u)),
                        ))
                    .toList(),
                onChanged: (MetricUnit? u) {
                  if (u != null) setState(() => _metricUpdateUnit = u);
                },
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _metricValueController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Nuevo valor ($updateUnitLabel)',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  final valueText = _metricValueController.text.trim();
                  if (valueText.isEmpty) return;
                  final userId = context.read<AuthBloc>().state.profile?.id;
                  if (userId == null || userId.isEmpty) {
                    AppAlerts.showInfo(
                        context, 'Inicia sesión para actualizar métricas');
                    return;
                  }
                  final unitToUse = _metricUpdateUnit ?? _metricUnit!;
                  try {
                    final value = double.parse(valueText);
                    await context.read<MetricsCubit>().saveMetric(
                          userId: userId,
                          capacityType: _metricCapacityType!,
                          exerciseKey: _metricExerciseKey!,
                          exerciseDisplayName: _metricDisplayName!,
                          value: value,
                          unit: unitToUse,
                        );
                    if (!mounted) return;
                    _loadUserMetricsIfNeeded();
                    _metricValueController.text = value
                        .toStringAsFixed(unitToUse == MetricUnit.score ? 1 : 0);
                    AppAlerts.showSuccessAtBottom(
                        context, 'Métrica actualizada');
                  } catch (e) {
                    if (!mounted) return;
                    AppAlerts.showError(context, 'Valor no válido: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRMInfo(Exercise exercise) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RM Actual',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Exercise Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Actualizado: ${_formatDate(exercise.date)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Weight Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    Text(
                      exercise.maxWeight.toString(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    Text(
                      'kg',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _maxWeightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nuevo RM (kg)',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  final weightText = _maxWeightController.text.trim();
                  if (weightText.isEmpty) return;
                  try {
                    final weight = double.parse(weightText);
                    context
                        .read<ExerciseCubit>()
                        .updateExercise(exercise.id, exercise.name, weight);
                    try {
                      await _saveStrengthMetricToFirebase(
                          context, exercise.name, weight,
                          unit: MetricUnit.kg);
                      if (!mounted) return;
                      AppAlerts.showSuccessAtBottom(context, 'RM actualizado');
                    } catch (e) {
                      if (!mounted) return;
                      AppAlerts.showError(context,
                          'Actualizado localmente. Error al sincronizar en la nube: $e');
                    }
                  } catch (e) {
                    AppAlerts.showWarning(
                        context, 'Por favor ingresa un número válido');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart(List<ExerciseProgress> progressData) {
    final theme = Theme.of(context);

    // We need at least 2 data points for a meaningful chart
    if (progressData.length < 2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.tertiary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progreso',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showDateRangeDialog,
                  icon: Icon(
                    Icons.date_range,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  label: Text(
                    'Filtrar Fechas',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay suficientes datos para mostrar la gráfica',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    const double minY = 0.0;
    const double maxY = 250.0; // Eje vertical fijo 0–250 kg para RM

    // Convert to spots for FL Chart
    final spots = progressData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.tertiary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Progreso',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'RM (kg) por fecha de registro',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _showDateRangeDialog,
                icon: Icon(
                  Icons.date_range,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                label: Text(
                  'Filtrar Fechas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final dateFormat = DateFormat('d MMM', 'es');
                // Mostrar cada fecha solo una vez (mismo día = una sola etiqueta)
                DateTime dayOf(int i) {
                  final d = progressData[i].date;
                  return DateTime(d.year, d.month, d.day);
                }

                final indicesToShow = <int>[];
                for (int i = 0; i < progressData.length; i++) {
                  if (i == 0 || dayOf(i) != dayOf(i - 1)) {
                    indicesToShow.add(i);
                  }
                }
                // Limitar a ~8 etiquetas para no saturar; submuestrear si hay muchas
                final int maxLabels = 8;
                final Set<int> displayed = indicesToShow.length <= maxLabels
                    ? indicesToShow.toSet()
                    : (List.generate(maxLabels, (i) {
                        final idx = indicesToShow.length > 1
                            ? (i * (indicesToShow.length - 1) / (maxLabels - 1))
                                .round()
                                .clamp(0, indicesToShow.length - 1)
                            : 0;
                        return indicesToShow[idx];
                      })).toSet();

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final index = value.round();
                            if (index >= 0 &&
                                index < progressData.length &&
                                displayed.contains(index)) {
                              final date = progressData[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  dateFormat.format(date),
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: 50,
                          getTitlesWidget: (value, meta) {
                            final v = value;
                            if (v < 0 || v > maxY) return const SizedBox();
                            final isWhole = v == v.roundToDouble();
                            final label = isWhole
                                ? '${v.round()} kg'
                                : '${v.toStringAsFixed(0)} kg';
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Text(
                                label,
                                style: theme.textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (progressData.length - 1).toDouble(),
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.map((spot) {
                          final y = spot.y.clamp(minY, maxY);
                          return FlSpot(
                              spot.x, minY + (y - minY) * _animation.value);
                        }).toList(),
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: theme.colorScheme.primary,
                              strokeWidth: 1,
                              strokeColor: theme.colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final index = touchedSpot.x.toInt();
                            if (index >= 0 && index < progressData.length) {
                              final progress = progressData[index];
                              final date = progress.date;
                              return LineTooltipItem(
                                '${progress.weight.toStringAsFixed(1)} kg\n${dateFormat.format(date)}',
                                theme.textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            }
                            return null;
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _metricAxisUnitLabel() {
    if (_metricUnit == null) return '';
    switch (_metricUnit!) {
      case MetricUnit.kg:
      case MetricUnit.lb:
        return ' kg';
      case MetricUnit.reps:
        return ' reps';
      case MetricUnit.seconds:
        return ' s';
      case MetricUnit.minutes:
        return ' min';
      case MetricUnit.hours:
        return ' h';
      case MetricUnit.score:
        return '';
    }
  }

  Widget _buildProgressChartForMetric(
      List<({double value, DateTime date})> progressList) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM', 'es');

    if (progressList.length < 2) {
      return Container(
        height: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Necesitas al menos 2 registros para ver el progreso',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final values = progressList.map((e) => e.value).toList();
    final minY = 0.0;
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.15)
        .clamp(10.0, double.infinity);
    final spots = progressList
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    int dayOf(int i) {
      final d = progressList[i].date;
      return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
    }

    final indicesToShow = <int>[];
    for (int i = 0; i < progressList.length; i++) {
      if (i == 0 || dayOf(i) != dayOf(i - 1)) indicesToShow.add(i);
    }
    final int maxLabels = 8;
    final displayed = indicesToShow.length <= maxLabels
        ? indicesToShow.toSet()
        : List.generate(maxLabels, (i) {
            final idx = indicesToShow.length > 1
                ? (i * (indicesToShow.length - 1) / (maxLabels - 1))
                    .round()
                    .clamp(0, indicesToShow.length - 1)
                : 0;
            return indicesToShow[idx];
          }).toSet();

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.tertiary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso (${_metricCapacityType?.displayName ?? ''})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Eje vertical: $_metricDisplayName en ${_unitLabel(_metricUnit ?? MetricUnit.reps)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index >= 0 &&
                            index < progressList.length &&
                            displayed.contains(index)) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dateFormat.format(progressList[index].date),
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > maxY) return const SizedBox();
                        final label = value == value.roundToDouble()
                            ? '${value.round()}${_metricAxisUnitLabel()}'
                            : '${value.toStringAsFixed(1)}${_metricAxisUnitLabel()}';
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            label,
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (progressList.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 5,
                        color: theme.colorScheme.primary,
                        strokeWidth: 1,
                        strokeColor: theme.colorScheme.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) =>
                        touchedSpots.map((touchedSpot) {
                      final index = touchedSpot.x.toInt();
                      if (index >= 0 && index < progressList.length) {
                        final p = progressList[index];
                        return LineTooltipItem(
                          '${p.value.toStringAsFixed(_metricUnit == MetricUnit.score ? 1 : 0)} ${_unitLabel(_metricUnit ?? MetricUnit.reps)}\n${dateFormat.format(p.date)}',
                          theme.textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      }
                      return null;
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTable(List<({double value, DateTime date})> progressList) {
    final theme = Theme.of(context);
    if (progressList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No hay registros en el rango de fechas',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    final best =
        progressList.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final last = progressList.first.value;
    final unitLabel = _unitLabel(_metricUnit ?? MetricUnit.reps);
    final entries = [
      {'label': 'Mejor marca', 'value': best},
      {'label': 'Última', 'value': last},
      if (best > 0) {'label': '75% del mejor', 'value': best * 0.75},
      if (best > 0) {'label': '50% del mejor', 'value': best * 0.5},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen por ${_metricCapacityType?.displayName ?? ''}',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              final val = (e['value'] as num).toDouble();
              final str = _metricUnit == MetricUnit.score
                  ? val.toStringAsFixed(1)
                  : val.toStringAsFixed(0);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['label'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '$str $unitLabel',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPercentagesTable(List<Map<String, dynamic>> percentages) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.tertiary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tabla de Porcentajes RM',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: percentages.length,
            itemBuilder: (context, index) {
              final item = percentages[index];
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item['percent']}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${item['weight']} kg',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ordenar por',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(
              icon: Icons.calendar_today,
              title: 'Fecha más reciente',
              subtitle: 'Ordenar del más reciente al más antiguo',
              selected: _filterType == 'date_desc',
              onTap: () {
                setState(() {
                  _filterType = 'date_desc';
                });
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              icon: Icons.calendar_today,
              title: 'Fecha más antigua',
              subtitle: 'Ordenar del más antiguo al más reciente',
              selected: _filterType == 'date_asc',
              onTap: () {
                setState(() {
                  _filterType = 'date_asc';
                });
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              icon: Icons.trending_up,
              title: 'Mayor crecimiento',
              subtitle: 'Ordenar por mayor aumento de peso',
              selected: _filterType == 'growth_desc',
              onTap: () {
                setState(() {
                  _filterType = 'growth_desc';
                });
                Navigator.pop(context);
              },
            ),
            _buildFilterOption(
              icon: Icons.trending_down,
              title: 'Menor crecimiento',
              subtitle: 'Ordenar por menor aumento de peso',
              selected: _filterType == 'growth_asc',
              onTap: () {
                setState(() {
                  _filterType = 'growth_asc';
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _showDateRangeDialog,
              icon: Icon(
                Icons.date_range,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Filtrar por rango de fechas',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.bold : null,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
