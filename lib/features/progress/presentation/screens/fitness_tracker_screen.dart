import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:IAEntrenar/utils/theme.dart';
import 'package:IAEntrenar/core/ui/charts.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/features/metrics/application/metrics_cubit.dart';
import 'package:IAEntrenar/features/metrics/application/metrics_state.dart';
import 'package:IAEntrenar/features/metrics/domain/entities/capacity_type.dart';
import 'package:IAEntrenar/features/metrics/domain/entities/fitness_metric_record.dart';
import 'package:IAEntrenar/features/progress/application/progress_cubit.dart';
import 'package:IAEntrenar/services/apple_health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FitnessTrackerScreen extends StatefulWidget {
  const FitnessTrackerScreen({super.key});

  @override
  State<FitnessTrackerScreen> createState() => _FitnessTrackerScreenState();
}

class _FitnessTrackerScreenState extends State<FitnessTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _contentAnimation;
  late ScrollController _scrollController;
  bool _isExpanded = false;

  // Activity rings data
  final int _currentSteps = 8547;
  final int _targetSteps = 10000;
  final int _currentCalories = 420;
  final int _targetCalories = 600;
  final int _activeMinutes = 38;
  final int _targetActiveMinutes = 45;

  // Chart data
  final List<String> _timeFilters = ['Día', 'Semana', 'Mes', 'Año'];
  String _selectedTimeFilter = 'Día';

  // Colores para el gráfico de desglose de ejercicio
  static const Color cardioColor = Color(0xFFE91E63); // Rosa
  static const Color strengthColor = Color(0xFF9C27B0); // Morado
  static const Color flexibilityColor = Color(0xFF00BCD4); // Cyan

  // Toggle visibility of chart series
  bool _showCardioData = true;
  bool _showStrengthData = true;
  bool _showFlexibilityData = true;

  // Health metrics (calculadas con Apple Health cuando hay datos)
  double? _computedStress; // 0-100
  double? _computedRecovery; // 0-100
  bool _stressRecoveryIsExample = true;

  final Map<String, int> _sleepHours = {
    'Lun': 7,
    'Mar': 6,
    'Mié': 7,
    'Jue': 8,
    'Vie': 6,
    'Sáb': 9,
    'Dom': 8,
  };

  final AppleHealthService _appleHealthService = AppleHealthService();
  AppleHealthData? _appleHealthData;
  bool _appleHealthLoading = false;

  Future<void> _loadAppleHealth() async {
    if (!AppleHealthService.isSupported) return;
    setState(() => _appleHealthLoading = true);
    try {
      final data = await _appleHealthService.fetchTodayData();
      if (!mounted) return;

      final computed = await _computeStressAndRecovery(data);
      setState(() {
        _appleHealthData = data;
        _computedStress = computed?.stress;
        _computedRecovery = computed?.recovery;
        _stressRecoveryIsExample = computed?.isExample ?? true;
        _appleHealthLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _appleHealthLoading = false);
    }
  }

  /// Cálculo KISS pero consistente:
  /// - Usa sueño (última noche), HRV y carga de actividad (min/cal/steps).
  /// - Normaliza relativo a una baseline personal (EWMA) guardada localmente.
  Future<({double stress, double recovery, bool isExample})?>
      _computeStressAndRecovery(
    AppleHealthData? data,
  ) async {
    if (data == null) return null;

    final sleep = data.sleepLastNightHours;
    final hrv = data.hrvMs;
    // Si falta sueño o HRV, devolvemos null y la UI lo marcará como ejemplo/0.
    if (sleep == null || hrv == null || sleep <= 0 || hrv <= 0) return null;

    final prefs = await SharedPreferences.getInstance();
    const alpha = 0.12; // EWMA suave (más estable)

    final prevBaselineHrv = prefs.getDouble('baseline_hrv_ms');
    final prevBaselineSleep = prefs.getDouble('baseline_sleep_h');

    final baselineHrv = _ewmaUpdate(
      prefs: prefs,
      key: 'baseline_hrv_ms',
      value: hrv,
      alpha: alpha,
    );
    _ewmaUpdate(
      prefs: prefs,
      key: 'baseline_sleep_h',
      value: sleep,
      alpha: alpha,
    );

    final minutes = (data.exerciseMinutes ?? 0).toDouble();
    final calories = (data.activeCalories ?? 0).toDouble();
    final steps = (data.steps ?? 0).toDouble();

    final sleepScore = _clamp01(_mapLinear(sleep, 5.0, 8.0)); // 5-8h
    // HRV: ratio vs baseline (capado). Si estás por encima de tu baseline, mejor.
    final hrvRatio = baselineHrv <= 0 ? 0.0 : (hrv / baselineHrv);
    final hrvScore =
        _clamp01((hrvRatio - 0.70) / (1.20 - 0.70)); // 0.70x..1.20x

    // Carga del día: 0..1 (más carga => menos recovery, más stress)
    final loadMinutes = _clamp01(minutes / 60.0);
    final loadCalories = _clamp01(calories / 600.0);
    final loadSteps = _clamp01(steps / 10000.0);
    final load =
        (0.45 * loadMinutes) + (0.35 * loadCalories) + (0.20 * loadSteps);

    // Recovery: sueño + HRV pesan más. Load penaliza ligeramente.
    final recovery = (100.0 *
            ((0.48 * sleepScore) + (0.42 * hrvScore) + (0.10 * (1.0 - load))))
        .clamp(0.0, 100.0);

    // Stress: inverso de sueño/HRV + carga.
    final stress = (100.0 *
            ((0.50 * (1.0 - sleepScore)) +
                (0.35 * (1.0 - hrvScore)) +
                (0.15 * load)))
        .clamp(0.0, 100.0);

    // Ejemplo si baseline aún no está estable (primeras sesiones).
    // Si aún no teníamos baseline (primeras sesiones), lo consideramos ejemplo.
    final isExample = prevBaselineHrv == null || prevBaselineSleep == null;
    return (stress: stress, recovery: recovery, isExample: isExample);
  }

  double _ewmaUpdate({
    required SharedPreferences prefs,
    required String key,
    required double value,
    required double alpha,
  }) {
    final prev = prefs.getDouble(key);
    final next = prev == null ? value : (alpha * value + (1 - alpha) * prev);
    // Fire-and-forget: persist baseline.
    prefs.setDouble(key, next);
    return next;
  }

  static double _clamp01(double v) => v.clamp(0.0, 1.0);

  /// Mapea linealmente x dentro [min..max] a [0..1].
  static double _mapLinear(double x, double min, double max) {
    if (max <= min) return 0.0;
    return (x - min) / (max - min);
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Animar anillos y datos al cargar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _contentAnimationController.forward();
    });
    // Cargar datos de Apple Health / Health Connect si está disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAppleHealth();
    });
    // Cargar métricas para el radar y gráficos (Firestore)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadMetricsData();
    });
  }

  void _loadMetricsData() {
    final userId = context.read<AuthBloc>().state.profile?.id;
    if (userId != null && userId.isNotEmpty) {
      context.read<MetricsCubit>().loadRadarData(userId);
      context.read<MetricsCubit>().loadUserMetrics(userId);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _contentAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double securityBotton = MediaQuery.of(context).padding.bottom + 65;
    final double securityTop = MediaQuery.of(context).padding.top + 15;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: AnimatedBuilder(
            animation: _contentAnimation,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(theme),
                    const SizedBox(height: 24),

                    // Activity Rings
                    Row(
                      children: [
                        _buildSectionTitle('Actividad Diaria ', theme),
                        if (AppleHealthService.isSupported) ...[
                          const SizedBox(width: 8),
                          if (_appleHealthLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Material(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                onTap: _loadAppleHealth,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.health_and_safety,
                                          size: 18,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        _appleHealthData != null
                                            ? 'Salud'
                                            : 'Conectar Salud',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActivityRings(theme),
                    const SizedBox(height: 32),

                    // Exercise Breakdown
                    _buildSectionTitle('Desglose de Ejercicio ', theme),
                    const SizedBox(height: 8),
                    _buildTimeFilters(theme),
                    const SizedBox(height: 12),
                    _buildTodayExerciseSummary(theme),
                    const SizedBox(height: 12),
                    _buildExerciseBreakdownChart(theme),
                    const SizedBox(height: 32),

                    // Health Metrics
                    _buildSectionTitle('Métricas de Salud ', theme),
                    const SizedBox(height: 16),
                    _buildHealthMetrics(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsetsGeometry.only(top: securityTop),
        child: DraggableFab(
          initPosition: Offset(MediaQuery.of(context).size.width - 20, 40),
          securityBottom: securityBotton,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedButton(
                index: 2,
                child: FloatingActionButton(
                  heroTag: 'timer',
                  backgroundColor: theme.colorScheme.secondary,
                  child: const Icon(Icons.timer_outlined),
                  onPressed: () => context.pushNamed('timer'),
                ),
              ),
              _buildAnimatedButton(
                index: 1,
                child: FloatingActionButton(
                  heroTag: 'settings',
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.settings),
                  onPressed: () => context.pushNamed('settings'),
                ),
              ),
              _buildAnimatedButton(
                index: 0,
                child: FloatingActionButton(
                  heroTag: 'profile',
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person),
                  onPressed: () => context.pushNamed('profile'),
                ),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'main',
                backgroundColor: theme.colorScheme.primary,
                child: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animationController,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                    if (_isExpanded) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final authState = context.watch<AuthBloc>().state;
    final userName = authState.profile?.displayName ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola, $userName!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateTime.now().toString().substring(0, 10),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Progreso hacia la meta: actual/meta, entre 0 y 1. Evita división por cero.
  static double _progressToGoal(int current, int target) {
    if (target <= 0) return 0.0;
    return (current / target).clamp(0.0, 1.0);
  }

  static String _formatWithCommas(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

  Widget _buildActivityRings(ThemeData theme) {
    final progressState = context.watch<ProgressCubit>().state;
    final snapshot = progressState.snapshot;
    // Preferir datos de Apple Health / Health Connect si están disponibles
    final currentCalories = _appleHealthData?.activeCalories ??
        snapshot?.today.caloriesBurned ??
        _currentCalories;
    final currentSteps =
        _appleHealthData?.steps ?? snapshot?.today.steps ?? _currentSteps;
    final currentActiveMinutes = _appleHealthData?.exerciseMinutes ??
        snapshot?.today.activeMinutes ??
        _activeMinutes;

    final moveProgress = _progressToGoal(currentCalories, _targetCalories);
    final exerciseProgress =
        _progressToGoal(currentActiveMinutes, _targetActiveMinutes);
    final standProgress = _progressToGoal(currentSteps, _targetSteps);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Activity Rings (CustomPaint con efecto glow y gradiente sutil)
              Expanded(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedBuilder(
                    animation: _contentAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ActivityRingsPainter(
                          moveProgress: moveProgress * _contentAnimation.value,
                          exerciseProgress:
                              exerciseProgress * _contentAnimation.value,
                          standProgress:
                              standProgress * _contentAnimation.value,
                          moveColor: AppTheme.moveRingColor,
                          exerciseColor: AppTheme.exerciseRingColor,
                          standColor: AppTheme.standRingColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Activity Stats: actual / meta en los tres (calorías, minutos, pasos)
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActivityStat(
                        icon: Icons.whatshot,
                        label: 'MOVIMIENTO',
                        value: '$currentCalories / $_targetCalories cal',
                        color: AppTheme.moveRingColor,
                        progress: moveProgress,
                        unit: '',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildActivityStat(
                        icon: Icons.timer,
                        label: 'EJERCICIO',
                        value:
                            '$currentActiveMinutes / $_targetActiveMinutes min',
                        color: AppTheme.exerciseRingColor,
                        progress: exerciseProgress,
                        unit: '',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildActivityStat(
                        icon: Icons.directions_walk,
                        label: 'PASOS',
                        value:
                            '${_formatWithCommas(currentSteps)} / ${_formatWithCommas(_targetSteps)} pasos',
                        color: AppTheme.standRingColor,
                        progress: standProgress,
                        unit: '',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double progress,
    required String unit,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _contentAnimation,
          builder: (context, child) {
            return Row(
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _contentAnimation,
          builder: (context, child) {
            final progressClamped = progress.clamp(0.0, 1.0);
            return LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth *
                    progressClamped *
                    _contentAnimation.value;
                return Stack(
                  children: [
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    Container(
                      height: 5,
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// Resumen de hoy: minutos de ejercicio, pasos y calorías (misma fuente que los anillos).
  Widget _buildTodayExerciseSummary(ThemeData theme) {
    final progressState = context.watch<ProgressCubit>().state;
    final snapshot = progressState.snapshot;
    final minutes = _appleHealthData?.exerciseMinutes ??
        snapshot?.today.activeMinutes ??
        _activeMinutes;
    final steps =
        _appleHealthData?.steps ?? snapshot?.today.steps ?? _currentSteps;
    final calories = _appleHealthData?.activeCalories ??
        snapshot?.today.caloriesBurned ??
        _currentCalories;

    String formatNumber(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryChip(
              theme: theme,
              icon: Icons.timer_outlined,
              value: '$minutes',
              label: 'Min ejercicio',
              color: AppTheme.exerciseRingColor,
            ),
          ),
          Expanded(
            child: _buildSummaryChip(
              theme: theme,
              icon: Icons.directions_walk,
              value: formatNumber(steps),
              label: 'Pasos',
              color: AppTheme.standRingColor,
            ),
          ),
          Expanded(
            child: _buildSummaryChip(
              theme: theme,
              icon: Icons.whatshot_outlined,
              value: '$calories',
              label: 'Cal',
              color: AppTheme.moveRingColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip({
    required ThemeData theme,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilters(ThemeData theme) {
    return Row(
      children: [
        // Expanded para que los chips ocupen el espacio restante
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _timeFilters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedTimeFilter == filter,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTimeFilter = filter;
                        });
                      }
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor: theme.colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: _selectedTimeFilter == filter
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: _selectedTimeFilter == filter
                          ? FontWeight.bold
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Icono de filtro permanece a la derecha, sin desplazarse
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => _buildFilterOptionsSheet(theme),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterOptionsSheet(ThemeData theme) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar datos',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mostrar categorías:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterToggle(
                      label: 'Cardio',
                      isSelected: _showCardioData,
                      color: cardioColor,
                      onChanged: (value) {
                        setModalState(() {
                          setState(() {
                            _showCardioData = value;
                          });
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterToggle(
                      label: 'Fuerza',
                      isSelected: _showStrengthData,
                      color: strengthColor,
                      onChanged: (value) {
                        setModalState(() {
                          setState(() {
                            _showStrengthData = value;
                          });
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterToggle(
                      label: 'Flexibilidad',
                      isSelected: _showFlexibilityData,
                      color: flexibilityColor,
                      onChanged: (value) {
                        setModalState(() {
                          setState(() {
                            _showFlexibilityData = value;
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Aplicar',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterToggle({
    required String label,
    required bool isSelected,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onChanged,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  /// Construye datos del gráfico de desglose para hoy por segmentos de 4 horas (0-4, 4-8, ..., 20-24).
  static List<StackedWorkoutData> _buildDailyBreakdownFromMetrics(
    List<FitnessMetricRecord> metrics,
    double animationValue, {
    required bool showCardio,
    required bool showStrength,
    required bool showFlexibility,
  }) {
    const segmentLabels = [
      '0-4h',
      '4-8h',
      '8-12h',
      '12-16h',
      '16-20h',
      '20-24h'
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final segmentSums = List.generate(
        6, (_) => [0.0, 0.0, 0.0]); // cardio, strength, flexibility

    for (final m in metrics) {
      final d = m.recordedAt;
      if (DateTime(d.year, d.month, d.day) != today) continue;
      final hour = d.hour;
      final segmentIndex = (hour / 4).floor().clamp(0, 5);
      final bucket = segmentSums[segmentIndex];
      switch (m.capacityType) {
        case CapacityType.strength:
          bucket[1] += m.value;
          break;
        case CapacityType.endurance:
        case CapacityType.speed:
        case CapacityType.cardio:
          bucket[0] += m.value;
          break;
        case CapacityType.mobility:
          bucket[2] += m.value;
          break;
      }
    }

    double maxCardio = 1, maxStrength = 1, maxFlex = 1;
    for (final bucket in segmentSums) {
      if (bucket[0] > maxCardio) maxCardio = bucket[0];
      if (bucket[1] > maxStrength) maxStrength = bucket[1];
      if (bucket[2] > maxFlex) maxFlex = bucket[2];
    }

    return List.generate(6, (i) {
      final raw = segmentSums[i];
      final cardio =
          showCardio ? (raw[0] / maxCardio * 40) * animationValue : 0.0;
      final strength =
          showStrength ? (raw[1] / maxStrength * 40) * animationValue : 0.0;
      final flexibility =
          showFlexibility ? (raw[2] / maxFlex * 40) * animationValue : 0.0;
      return StackedWorkoutData(
        xLabel: segmentLabels[i],
        values: [cardio, strength, flexibility],
      );
    });
  }

  /// Construye datos del gráfico de desglose a partir de métricas reales (últimos 7 días).
  static List<StackedWorkoutData> _buildWeeklyBreakdownFromMetrics(
    List<FitnessMetricRecord> metrics,
    double animationValue, {
    required bool showCardio,
    required bool showStrength,
    required bool showFlexibility,
  }) {
    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    final days = List.generate(7, (i) => startDate.add(Duration(days: i)));

    final dailySums = <DateTime, List<double>>{};
    for (final d in days) {
      dailySums[DateTime(d.year, d.month, d.day)] = [
        0.0,
        0.0,
        0.0
      ]; // cardio, strength, flexibility
    }

    for (final m in metrics) {
      final day =
          DateTime(m.recordedAt.year, m.recordedAt.month, m.recordedAt.day);
      final bucket = dailySums[day];
      if (bucket == null) continue;
      switch (m.capacityType) {
        case CapacityType.strength:
          bucket[1] += m.value;
          break;
        case CapacityType.endurance:
        case CapacityType.speed:
        case CapacityType.cardio:
          bucket[0] += m.value;
          break;
        case CapacityType.mobility:
          bucket[2] += m.value;
          break;
      }
    }

    double maxCardio = 1, maxStrength = 1, maxFlex = 1;
    for (final bucket in dailySums.values) {
      if (bucket[0] > maxCardio) maxCardio = bucket[0];
      if (bucket[1] > maxStrength) maxStrength = bucket[1];
      if (bucket[2] > maxFlex) maxFlex = bucket[2];
    }

    return days.map((d) {
      final key = DateTime(d.year, d.month, d.day);
      final raw = dailySums[key]!;
      final cardio =
          showCardio ? (raw[0] / maxCardio * 40) * animationValue : 0.0;
      final strength =
          showStrength ? (raw[1] / maxStrength * 40) * animationValue : 0.0;
      final flexibility =
          showFlexibility ? (raw[2] / maxFlex * 40) * animationValue : 0.0;
      return StackedWorkoutData(
        xLabel: dayLabels[d.weekday - 1],
        values: [cardio, strength, flexibility],
      );
    }).toList();
  }

  Widget _buildExerciseBreakdownChart(ThemeData theme) {
    return BlocBuilder<MetricsCubit, MetricsState>(
      buildWhen: (prev, next) =>
          prev.metrics != next.metrics ||
          prev.metrics.isEmpty != next.metrics.isEmpty,
      builder: (context, metricsState) {
        List<StackedWorkoutData> workoutData;
        final hasMetrics = metricsState.metrics.isNotEmpty;
        final isDay = _selectedTimeFilter == 'Día';
        final isWeek = _selectedTimeFilter == 'Semana';

        final today = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
        final hasMetricsToday = hasMetrics &&
            metricsState.metrics.any((m) =>
                DateTime(
                    m.recordedAt.year, m.recordedAt.month, m.recordedAt.day) ==
                today);

        if (isDay && hasMetricsToday) {
          workoutData = _buildDailyBreakdownFromMetrics(
            metricsState.metrics,
            _contentAnimation.value,
            showCardio: _showCardioData,
            showStrength: _showStrengthData,
            showFlexibility: _showFlexibilityData,
          );
        } else if (isWeek && hasMetrics) {
          workoutData = _buildWeeklyBreakdownFromMetrics(
            metricsState.metrics,
            _contentAnimation.value,
            showCardio: _showCardioData,
            showStrength: _showStrengthData,
            showFlexibility: _showFlexibilityData,
          );
        } else {
          workoutData = [];
        }

        final hasData = workoutData.isNotEmpty;
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (_showCardioData)
                    _buildLegendItem('Cardio', cardioColor, theme),
                  if (_showStrengthData)
                    _buildLegendItem('Fuerza', strengthColor, theme),
                  if (_showFlexibilityData)
                    _buildLegendItem('Flexibilidad', flexibilityColor, theme),
                ],
              ),
              if (hasData)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _selectedTimeFilter == 'Día'
                        ? 'Actividad por franja horaria (hoy). Eje vertical: nivel normalizado.'
                        : 'Actividad relativa por día (según métricas guardadas). Eje vertical: nivel normalizado.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: hasData
                    ? AnimatedBuilder(
                        animation: _contentAnimation,
                        builder: (context, child) {
                          return WorkoutStackedColumnChart(
                            workoutData: workoutData,
                            cardioColor: cardioColor,
                            strengthColor: strengthColor,
                            flexibilityColor: flexibilityColor,
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 48,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedTimeFilter == 'Semana'
                                  ? 'No hay métricas para esta semana.\nRegistra ejercicios en la calculadora RM\no añade métricas de capacidad.'
                                  : 'No hay datos de métricas en esta sección',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildHealthMetrics(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final childAspectRatio = width < 380 ? 0.82 : 1.0;

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStressLevelCard(theme),
                _buildRecoveryScoreCard(theme),
                _buildSleepQualityCard(theme),
                _buildHRVCard(theme),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _buildFitnessRadarChart(theme),
      ],
    );
  }

  Widget _buildFitnessRadarChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perfil de Capacidades',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Análisis de tus habilidades físicas actuales',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<MetricsCubit, MetricsState>(
            buildWhen: (prev, curr) =>
                prev.radarData != curr.radarData ||
                prev.radarLoading != curr.radarLoading,
            builder: (context, metricsState) {
              final data = metricsState.radarData.isNotEmpty
                  ? metricsState.radarData
                  : const {
                      'Fuerza': 0.0,
                      'Resistencia': 0.0,
                      'Velocidad': 0.0,
                      'Movilidad': 0.0,
                      'Cardio': 0.0,
                    };
              return AnimatedBuilder(
                animation: _contentAnimation,
                builder: (context, _) {
                  final animatedData = data.map((key, value) =>
                      MapEntry(key, value * _contentAnimation.value));
                  return metricsState.radarLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : FitnessRadarChart(
                          fitnessAttributes: animatedData,
                          maxValue: 10.0,
                        );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStressLevelCard(ThemeData theme) {
    final baseStress = (_computedStress ?? 0.0).clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.moveRingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.spa,
                  color: AppTheme.moveRingColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Estrés',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                final stressValue = baseStress * _contentAnimation.value;
                final stressColor = stressValue > 35
                    ? AppTheme.moveRingColor
                    : stressValue > 20
                        ? Colors.orange
                        : AppTheme.exerciseRingColor;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stressValue.toInt().toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: stressColor,
                      ),
                    ),
                    if (_stressRecoveryIsExample)
                      Text(
                        '(Ejemplo)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Spacer(),
          Text(
            stressDescription(baseStress),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String stressDescription(double value) {
    if (value > 35) return 'Alto';
    if (value > 20) return 'Moderado';
    return 'Bajo';
  }

  Widget _buildRecoveryScoreCard(ThemeData theme) {
    final baseRecovery = (_computedRecovery ?? 0.0).clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.exerciseRingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.battery_charging_full,
                  color: AppTheme.exerciseRingColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recuperación',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                final recoveryScoreValue =
                    baseRecovery * _contentAnimation.value;
                final recoveryColor = recoveryScoreValue > 70
                    ? AppTheme.exerciseRingColor
                    : recoveryScoreValue > 50
                        ? Colors.orange
                        : AppTheme.moveRingColor;
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            recoveryScoreValue.toInt().toString(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: recoveryColor,
                            ),
                          ),
                          if (_stressRecoveryIsExample)
                            Text(
                              '(Ejemplo)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Text(
                          '/100',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              recoveryDescription(baseRecovery),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String recoveryDescription(double value) {
    if (value > 70) return 'Óptimo';
    if (value > 50) return 'Bueno';
    return 'Necesitas descanso';
  }

  Widget _buildSleepQualityCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.standRingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  color: AppTheme.standRingColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Sueño',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceBetween,
                    maxY: 10,
                    minY: 0,
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() % 2 == 0 &&
                                value.toInt() < _sleepHours.length) {
                              final dayKey =
                                  _sleepHours.keys.elementAt(value.toInt());
                              return Text(
                                dayKey.substring(0, 1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 8,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 16,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _sleepHours.entries.map((entry) {
                      final index =
                          _sleepHours.keys.toList().indexOf(entry.key);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value * _contentAnimation.value,
                            width: 4,
                            color: getSleepQualityColor(entry.value),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    gridData: const FlGridData(show: false),
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                final sleepHours = _appleHealthData?.sleepLastNightHours ?? 0.0;
                final sleepDisplay =
                    (sleepHours * _contentAnimation.value).toStringAsFixed(1);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        'Última noche',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sleepDisplay,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: getSleepQualityColor(sleepHours),
                            ),
                          ),
                          Text(
                            ' h',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color getSleepQualityColor(num hours) {
    if (hours >= 7) return AppTheme.exerciseRingColor;
    if (hours >= 6) return Colors.orange;
    return AppTheme.moveRingColor;
  }

  Widget _buildHRVCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.moveRingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: AppTheme.moveRingColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HRV',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _contentAnimation,
              builder: (context, child) {
                final hrvBase = _appleHealthData?.hrvMs ?? 52.0;
                final hrvValue = hrvBase * _contentAnimation.value;
                final isMock = _appleHealthData?.hrvMs == null;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${hrvValue.toInt()} ms',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.moveRingColor,
                      ),
                    ),
                    if (isMock)
                      Text(
                        '(Ejemplo)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              'Normal',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedButton({
    required Widget child,
    required int index,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isExpanded ? 1.0 : 0.0,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: _isExpanded
            ? Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: child,
              )
            : const SizedBox(width: 56, height: 0),
      ),
    );
  }
}

/// Pintor de los 3 anillos de actividad con glow y gradiente sutiles.
class ActivityRingsPainter extends CustomPainter {
  ActivityRingsPainter({
    required this.moveProgress,
    required this.exerciseProgress,
    required this.standProgress,
    required this.moveColor,
    required this.exerciseColor,
    required this.standColor,
  });

  final double moveProgress;
  final double exerciseProgress;
  final double standProgress;
  final Color moveColor;
  final Color exerciseColor;
  final Color standColor;

  static const double _glowOpacity = 0.08;
  static const double _gradientHighlight = 0.1;
  static const double _glowWidthExtra = 3;

  static const double _gapBetweenRings = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.075;
    final radius1 = size.width * 0.4;
    final radius2 = radius1 - strokeWidth - _gapBetweenRings;
    final radius3 = radius2 - strokeWidth - _gapBetweenRings;
    const startAngle = -math.pi / 2;

    // Fondos (track)
    _drawRing(
        canvas, center, radius1, strokeWidth, moveColor.withOpacity(0.2), 1.0);
    _drawRing(canvas, center, radius2, strokeWidth,
        exerciseColor.withOpacity(0.2), 1.0);
    _drawRing(
        canvas, center, radius3, strokeWidth, standColor.withOpacity(0.2), 1.0);

    // Anillo 1: glow sutil + barra con gradiente + cap
    _drawRingGlow(
        canvas, center, radius1, strokeWidth, moveColor, moveProgress);
    _drawRingGradient(canvas, center, radius1, strokeWidth, moveColor,
        startAngle, moveProgress);
    if (moveProgress > 0 && moveProgress < 1.0) {
      _drawCap(canvas, center, radius1, strokeWidth, moveColor, moveProgress);
    }

    _drawRingGlow(
        canvas, center, radius2, strokeWidth, exerciseColor, exerciseProgress);
    _drawRingGradient(canvas, center, radius2, strokeWidth, exerciseColor,
        startAngle, exerciseProgress);
    if (exerciseProgress > 0 && exerciseProgress < 1.0) {
      _drawCap(canvas, center, radius2, strokeWidth, exerciseColor,
          exerciseProgress);
    }

    _drawRingGlow(
        canvas, center, radius3, strokeWidth, standColor, standProgress);
    _drawRingGradient(canvas, center, radius3, strokeWidth, standColor,
        startAngle, standProgress);
    if (standProgress > 0 && standProgress < 1.0) {
      _drawCap(canvas, center, radius3, strokeWidth, standColor, standProgress);
    }
  }

  void _drawRing(Canvas canvas, Offset center, double radius,
      double strokeWidth, Color color, double progress) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, paint);
  }

  void _drawRingGlow(Canvas canvas, Offset center, double radius,
      double strokeWidth, Color color, double progress) {
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    final paint = Paint()
      ..color = color.withOpacity(_glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + _glowWidthExtra
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, paint);
  }

  void _drawRingGradient(Canvas canvas, Offset center, double radius,
      double strokeWidth, Color color, double startAngle, double progress) {
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius * 1.5);
    final sweep = 2 * math.pi * progress;
    final highlightColor = Color.lerp(color, Colors.white, _gradientHighlight)!;
    final shader = SweepGradient(
      center: Alignment.center,
      startAngle: startAngle,
      endAngle: startAngle + sweep,
      colors: [highlightColor, color],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  void _drawCap(Canvas canvas, Offset center, double radius, double strokeWidth,
      Color color, double progress) {
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final capRadius = strokeWidth / 2;
    final capCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(capCenter, capRadius, paint);
  }

  @override
  bool shouldRepaint(covariant ActivityRingsPainter old) {
    return old.moveProgress != moveProgress ||
        old.exerciseProgress != exerciseProgress ||
        old.standProgress != standProgress;
  }
}
