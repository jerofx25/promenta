import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';

class RMCalculatorScreen extends StatefulWidget {
  const RMCalculatorScreen({super.key});

  @override
  _RMCalculatorScreenState createState() => _RMCalculatorScreenState();
}

class _RMCalculatorScreenState extends State<RMCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _exerciseNameController = TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;

  String _filterType =
      'date_desc'; // Options: date_asc, date_desc, growth_asc, growth_desc
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

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

    // Initialize with the current selected exercise if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExerciseProvider>(context, listen: false);
      final selectedExercise = provider.selectedExercise;

      if (selectedExercise != null) {
        _exerciseNameController.text = selectedExercise.name;
        _maxWeightController.text = selectedExercise.maxWeight.toString();
      }
    });
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _maxWeightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    final weightController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Añadir Ejercicio',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Peso Máximo (RM)',
                suffixText: 'kg',
                prefixIcon: Icon(
                  Icons.monitor_weight,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // Validate and add the exercise
              final name = nameController.text.trim();
              final weightText = weightController.text.trim();

              if (name.isEmpty || weightText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Por favor completa todos los campos')),
                );
                return;
              }

              try {
                final weight = double.parse(weightText);
                Provider.of<ExerciseProvider>(context, listen: false)
                    .addExercise(name, weight);
                Navigator.pop(context);

                // Update the text controllers with the new exercise
                _exerciseNameController.text = name;
                _maxWeightController.text = weight.toString();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Por favor ingresa un número válido para el peso')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
            icon: const Icon(Icons.filter_list),
            color: theme.colorScheme.primary,
            onPressed: () {
              // Show filter options
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
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, child) {
          final selectedExercise = provider.selectedExercise;
          if (selectedExercise == null) {
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

          final progressData = provider.getProgressForExercise(
            selectedExercise.id,
            ascending: _filterType.contains('asc'),
          );

          final percentages =
              provider.calculateRMPercentages(selectedExercise.maxWeight);

          return Stack(
            children: [
              // Background image
              Opacity(
                opacity: 0.1,
                child: Image.network(
                  "https://pixabay.com/get/g8ad5e548d5ddcf2725df7030d1ce60b9716199fdc546fef5f5a21b83ee577bf2d7ae293ea2772e6f21a6ff6f4911892049390fcbd14cca538f02301543a17a30_1280.jpg",
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // Content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exercise Selection Dropdown
                        _buildExerciseSelector(provider),

                        const SizedBox(height: 24),

                        // Current RM Info
                        _buildCurrentRMInfo(selectedExercise),

                        const SizedBox(height: 24),

                        // Progress Chart
                        _buildProgressChart(progressData),

                        const SizedBox(height: 24),

                        // Percentages Table
                        _buildPercentagesTable(percentages),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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

  Widget _buildExerciseSelector(ExerciseProvider provider) {
    final theme = Theme.of(context);
    final exercises = provider.exercises;
    final selectedExercise = provider.selectedExercise;

    // Creamos una lista de etiquetas para el dropdown
    final List<String> exerciseNames = exercises.map((e) => e.name).toList();

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
            items: exerciseNames,
            initialItem: selectedExercise?.name,
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
            onChanged: (String? value) {
              if (value != null) {
                // Buscar el ID del ejercicio por su nombre
                final exercise = exercises.firstWhere(
                  (e) => e.name == value,
                  orElse: () => exercises.first,
                );
                provider.setSelectedExercise(exercise.id);

                // Update the text controllers
                final selected = provider.selectedExercise;
                if (selected != null) {
                  _exerciseNameController.text = selected.name;
                  _maxWeightController.text = selected.maxWeight.toString();
                }
              }
            },
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
                onPressed: () {
                  // Update the exercise RM
                  final weightText = _maxWeightController.text.trim();
                  if (weightText.isNotEmpty) {
                    try {
                      final weight = double.parse(weightText);
                      Provider.of<ExerciseProvider>(context, listen: false)
                          .updateExercise(exercise.id, exercise.name, weight);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('RM actualizado correctamente')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Por favor ingresa un número válido')),
                      );
                    }
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

    // Find min and max values for better scaling
    double minY =
        progressData.map((e) => e.weight).reduce((a, b) => a < b ? a : b) * 0.9;
    double maxY =
        progressData.map((e) => e.weight).reduce((a, b) => a > b ? a : b) * 1.1;

    // Convert to spots for FL Chart
    final spots = progressData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    return Container(
      height: 280,
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
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
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
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 &&
                                value.toInt() < progressData.length) {
                              // Show dates for selected entries
                              if (value.toInt() %
                                      (progressData.length ~/ 5 + 1) ==
                                  0) {
                                final date = progressData[value.toInt()].date;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                );
                              }
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                value.toInt().toString(),
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
                          return FlSpot(spot.x,
                              minY + (spot.y - minY) * _animation.value);
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
                                '${progress.weight} kg\n${date.day}/${date.month}/${date.year}',
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
                  children: [
                    Text(
                      '${item['percent']}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item['weight']} kg',
                      style: theme.textTheme.bodyMedium,
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
