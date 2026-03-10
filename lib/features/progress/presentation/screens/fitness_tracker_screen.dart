import 'package:IAEntrenar/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:IAEntrenar/utils/theme.dart';
import 'package:IAEntrenar/core/ui/charts.dart';
import 'package:draggable_fab/draggable_fab.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/features/progress/application/progress_cubit.dart';

class FitnessTrackerScreen extends StatefulWidget {
  const FitnessTrackerScreen({super.key});

  @override
  _FitnessTrackerScreenState createState() => _FitnessTrackerScreenState();
}

class _FitnessTrackerScreenState extends State<FitnessTrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late ScrollController _scrollController;
  bool _isExpanded = false;

  // Activity rings data
  final int _currentSteps = 8547;
  final int _targetSteps = 10000;
  final int _currentCalories = 420;
  final int _targetCalories = 600;
  final int _activeMinutes = 38;
  final int _targetActiveMinutes = 60;

  // Chart data
  final List<String> _timeFilters = ['Día', 'Semana', 'Mes', 'Año'];
  String _selectedTimeFilter = 'Día';

  // Toggle visibility of chart series
  bool _showCardioData = true;
  bool _showStrengthData = true;
  bool _showFlexibilityData = true;

  // Health metrics
  final Map<String, double> _stressLevels = {
    'Lun': 35,
    'Mar': 42,
    'Mié': 38,
    'Jue': 25,
    'Vie': 30,
    'Sáb': 20,
    'Dom': 15,
  };

  final Map<String, int> _sleepHours = {
    'Lun': 7,
    'Mar': 6,
    'Mié': 7,
    'Jue': 8,
    'Vie': 6,
    'Sáb': 9,
    'Dom': 8,
  };

  final double _recoveryScore = 79;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomButton(
                  text: 'Nuevo Entrenamiento',
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                    if (context.mounted) context.goNamed('login');
                  },
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Ir a Home',
                  onPressed: () {
                    if (context.mounted) context.goNamed('home');
                  },
                  width: double.infinity,
                ),
                const SizedBox(height: 16),
                // Header
                _buildHeader(theme),
                const SizedBox(height: 24),

                // Activity Rings
                _buildSectionTitle('Actividad Diaria 🏃', theme),
                const SizedBox(height: 16),
                _buildActivityRings(theme),
                const SizedBox(height: 32),

                // Exercise Breakdown
                _buildSectionTitle('Desglose de Ejercicio 📊', theme),
                const SizedBox(height: 8),
                _buildTimeFilters(theme),
                const SizedBox(height: 8),
                _buildExerciseBreakdownChart(theme),
                const SizedBox(height: 32),

                // Health Metrics
                _buildSectionTitle('Métricas de Salud ❤️', theme),
                const SizedBox(height: 16),
                _buildHealthMetrics(theme),
                const SizedBox(height: 24),
              ],
            ),
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
              _buildAnimatedButton(
                index: 0,
                child: FloatingActionButton(
                  heroTag: 'profile',
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person),
                  onPressed: () => context.goNamed('profile'),
                ),
              ),
              _buildAnimatedButton(
                index: 1,
                child: FloatingActionButton(
                  heroTag: 'settings',
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.settings),
                  onPressed: () {
                    // Implementar navegación a configuración
                  },
                ),
              ),
              _buildAnimatedButton(
                index: 2,
                child: FloatingActionButton(
                  heroTag: 'timer',
                  backgroundColor: theme.colorScheme.secondary,
                  child: const Icon(Icons.timer_outlined),
                  onPressed: () => context.goNamed('timer'),
                ),
              ),
              _buildAnimatedButton(
                index: 3,
                child: FloatingActionButton(
                  heroTag: 'progress',
                  backgroundColor: theme.colorScheme.tertiary,
                  child: const Icon(Icons.bar_chart_outlined),
                  onPressed: () => context.goNamed('progress'),
                ),
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
        // Envolvemos el texto en Expanded para evitar overflow
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

  Widget _buildActivityRings(ThemeData theme) {
    final progressState = context.watch<ProgressCubit>().state;
    final snapshot = progressState.snapshot;
    final currentCalories =
        snapshot?.today.caloriesBurned ?? _currentCalories;
    final currentSteps = snapshot?.today.steps ?? _currentSteps;
    final currentActiveMinutes =
        snapshot?.today.activeMinutes ?? _activeMinutes;
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
              // Activity Rings Animation
              Expanded(
                flex: 4,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ActivityRingsPainter(
                          moveProgress: currentCalories /
                              _targetCalories *
                              _progressAnimation.value,
                          exerciseProgress: currentActiveMinutes /
                              _targetActiveMinutes *
                              _progressAnimation.value,
                          standProgress: currentSteps /
                              _targetSteps *
                              _progressAnimation.value,
                          moveColor: AppTheme.moveRingColor,
                          exerciseColor: AppTheme.exerciseRingColor,
                          standColor: AppTheme.standRingColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Activity Stats
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
                        value: '$currentCalories/$_targetCalories',
                        color: AppTheme.moveRingColor,
                        progress: currentCalories / _targetCalories,
                        unit: 'CAL',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildActivityStat(
                        icon: Icons.timer,
                        label: 'EJERCICIO',
                        value: '$currentActiveMinutes/$_targetActiveMinutes',
                        color: AppTheme.exerciseRingColor,
                        progress:
                            currentActiveMinutes / _targetActiveMinutes,
                        unit: 'MIN',
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                      _buildActivityStat(
                        icon: Icons.directions_walk,
                        label: 'PASOS',
                        value: currentSteps.toString().replaceAllMapped(
                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                              (Match m) => '${m[1]},',
                            ),
                        color: AppTheme.standRingColor,
                        progress: currentSteps / _targetSteps,
                        unit:
                            'DE ${_targetSteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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
          animation: _progressAnimation,
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
          animation: _progressAnimation,
          builder: (context, child) {
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
                  width: (MediaQuery.of(context).size.width * 0.35) *
                      progress *
                      _progressAnimation.value,
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
                      color: AppTheme.moveRingColor,
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
                      color: AppTheme.exerciseRingColor,
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
                      color: AppTheme.standRingColor,
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

  Widget _buildExerciseBreakdownChart(ThemeData theme) {
    // Generate sample data based on selected time filter
    final List<String> labels = _selectedTimeFilter == 'Día'
        ? ['M', 'T', 'N', 'T', 'E']
        : _selectedTimeFilter == 'Semana'
            ? ['L', 'M', 'X', 'J', 'V', 'S', 'D']
            : _selectedTimeFilter == 'Mes'
                ? ['S1', 'S2', 'S3', 'S4']
                : ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    // Generate workout data for the stacked column chart
    List<StackedWorkoutData> workoutData = [];
    final random = math.Random();

    for (int i = 0; i < labels.length; i++) {
      final cardioValue = _showCardioData
          ? (20 + random.nextInt(30)) * _progressAnimation.value
          : 0.0;
      final strengthValue = _showStrengthData
          ? (15 + random.nextInt(35)) * _progressAnimation.value
          : 0.0;
      final flexibilityValue = _showFlexibilityData
          ? (10 + random.nextInt(20)) * _progressAnimation.value
          : 0.0;

      workoutData.add(StackedWorkoutData(
        xLabel: labels[i],
        values: [cardioValue, strengthValue, flexibilityValue],
      ));
    }

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
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (_showCardioData)
                _buildLegendItem('Cardio', AppTheme.moveRingColor, theme),
              if (_showStrengthData)
                _buildLegendItem('Fuerza', AppTheme.exerciseRingColor, theme),
              if (_showFlexibilityData)
                _buildLegendItem(
                    'Flexibilidad', AppTheme.standRingColor, theme),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          Expanded(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return WorkoutStackedColumnChart(
                  workoutData: workoutData,
                );
              },
            ),
          ),
        ],
      ),
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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            _buildStressLevelCard(theme),
            _buildRecoveryScoreCard(theme),
            _buildSleepQualityCard(theme),
            _buildHRVCard(theme),
          ],
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
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, _) {
              // Get sample data and multiply by animation value for effect
              final data = FitnessRadarData.getSampleFitnessData();
              final animatedData = data.map((key, value) =>
                  MapEntry(key, value * _progressAnimation.value));

              return FitnessRadarChart(
                fitnessAttributes: animatedData,
                maxValue: 10.0,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStressLevelCard(ThemeData theme) {
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
              animation: _progressAnimation,
              builder: (context, child) {
                final stressValue =
                    _stressLevels.values.last * _progressAnimation.value;
                final stressColor = stressValue > 35
                    ? AppTheme.moveRingColor
                    : stressValue > 20
                        ? Colors.orange
                        : AppTheme.exerciseRingColor;
                return Text(
                  stressValue.toInt().toString(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: stressColor,
                  ),
                );
              },
            ),
          ),
          const Spacer(),
          Text(
            stressDescription(_stressLevels.values.last),
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
              Text(
                'Recuperación',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final recoveryScoreValue =
                    _recoveryScore * _progressAnimation.value;
                final recoveryColor = recoveryScoreValue > 70
                    ? AppTheme.exerciseRingColor
                    : recoveryScoreValue > 50
                        ? Colors.orange
                        : AppTheme.moveRingColor;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      recoveryScoreValue.toInt().toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: recoveryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        '/100',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Spacer(),
          Text(
            recoveryDescription(_recoveryScore),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
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
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return SizedBox(
                height: 65,
                child: BarChart(
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
                          reservedSize: 20,
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
                            toY: entry.value * _progressAnimation.value,
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
                ),
              );
            },
          ),
          const Spacer(),
          Center(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                final avgSleep = _sleepHours.values.reduce((a, b) => a + b) /
                    _sleepHours.length;
                final avgSleepDisplay =
                    (avgSleep * _progressAnimation.value).toStringAsFixed(1);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      avgSleepDisplay,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: getSleepQualityColor(avgSleep),
                      ),
                    ),
                    Text(
                      ' horas prom.',
                      style: theme.textTheme.bodySmall,
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
              animation: _progressAnimation,
              builder: (context, child) {
                final hrvValue = 52 * _progressAnimation.value;
                return Text(
                  '${hrvValue.toInt()} ms',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.moveRingColor,
                  ),
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
      duration: const Duration(milliseconds: 1200),
      opacity: _isExpanded ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(
          0,
          _isExpanded ? (index + 1) * 18.0 : 0,
          0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1500),
          margin: EdgeInsets.only(
            top: _isExpanded ? 10 : 0,
            bottom: _isExpanded ? 8 : 0,
          ),
          child: _isExpanded ? child : const SizedBox(),
        ),
      ),
    );
  }
}

class ActivityRingsPainter extends CustomPainter {
  final double moveProgress;
  final double exerciseProgress;
  final double standProgress;
  final Color moveColor;
  final Color exerciseColor;
  final Color standColor;

  ActivityRingsPainter({
    required this.moveProgress,
    required this.exerciseProgress,
    required this.standProgress,
    required this.moveColor,
    required this.exerciseColor,
    required this.standColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius1 = size.width * 0.4;
    final radius2 = size.width * 0.325;
    final radius3 = size.width * 0.25;
    final strokeWidth = size.width * 0.075;

    // Background rings
    _drawRing(
        canvas, center, radius1, strokeWidth, moveColor.withOpacity(0.2), 1.0);
    _drawRing(canvas, center, radius2, strokeWidth,
        exerciseColor.withOpacity(0.2), 1.0);
    _drawRing(
        canvas, center, radius3, strokeWidth, standColor.withOpacity(0.2), 1.0);

    // Progress rings
    _drawRing(canvas, center, radius1, strokeWidth, moveColor, moveProgress);
    _drawRing(
        canvas, center, radius2, strokeWidth, exerciseColor, exerciseProgress);
    _drawRing(canvas, center, radius3, strokeWidth, standColor, standProgress);

    // Draw ring caps if progress is not complete
    if (moveProgress < 1.0) {
      _drawCap(canvas, center, radius1, strokeWidth, moveColor, moveProgress);
    }
    if (exerciseProgress < 1.0) {
      _drawCap(canvas, center, radius2, strokeWidth, exerciseColor,
          exerciseProgress);
    }
    if (standProgress < 1.0) {
      _drawCap(canvas, center, radius3, strokeWidth, standColor, standProgress);
    }
  }

  void _drawRing(Canvas canvas, Offset center, double radius,
      double strokeWidth, Color color, double progress) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  void _drawCap(Canvas canvas, Offset center, double radius, double strokeWidth,
      Color color, double progress) {
    final angle = -math.pi / 2 + 2 * math.pi * progress;
    final capRadius = strokeWidth / 2;

    final capCenter = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );

    final capPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(capCenter, capRadius, capPaint);
  }

  @override
  bool shouldRepaint(covariant ActivityRingsPainter oldDelegate) {
    return oldDelegate.moveProgress != moveProgress ||
        oldDelegate.exerciseProgress != exerciseProgress ||
        oldDelegate.standProgress != standProgress;
  }
}