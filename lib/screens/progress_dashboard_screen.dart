import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';
import '../widgets/progress_pie_chart.dart';
import '../widgets/stacked_column_chart.dart';
import '../widgets/radar_chart.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _topTabController;
  late TabController _bottomTabController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Activity stats
  final int _caloriesBurned = 685;
  final int _steps = 8754;
  final int _distance = 5;
  final int _activeMinutes = 62;

  // Weekly workout stats
  final List<double> _weeklyWorkouts = [3, 4, 1, 2, 5, 2, 3];

  // Heart rate data
  final List<FlSpot> _heartRateData = [
    const FlSpot(0, 72),
    const FlSpot(1, 74),
    const FlSpot(2, 95),
    const FlSpot(3, 120),
    const FlSpot(4, 110),
    const FlSpot(5, 89),
    const FlSpot(6, 75),
    const FlSpot(7, 70),
  ];

  // Upcoming workouts
  final List<Map<String, dynamic>> _upcomingWorkouts = [
    {
      'name': 'Upper Body Strength',
      'time': '09:00 AM',
      'duration': '45 min',
      'trainer': 'Alex',
      'image': 'weights'
    },
    {
      'name': 'HIIT Cardio',
      'time': '12:30 PM',
      'duration': '30 min',
      'trainer': 'Sophia',
      'image': 'cardio'
    },
    {
      'name': 'Mobility & Stretching',
      'time': '06:00 PM',
      'duration': '20 min',
      'trainer': 'Miguel',
      'image': 'stretching'
    },
  ];

  @override
  void initState() {
    super.initState();
    _topTabController = TabController(length: 3, vsync: this);
    _bottomTabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _topTabController.dispose();
    _bottomTabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E23),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildActivityStats(),
                    const SizedBox(height: 20),
                    _buildTopTabBar(),
                    // Fijamos una altura para el TabBarView y cada pestaña se encarga de su scroll interno
                    SizedBox(
                      height: 300,
                      child: _buildTabContent(),
                    ),
                    const SizedBox(height: 20),
                    _buildUpcomingWorkouts(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu rendimiento',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Actividad Diaria',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStats() {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return ActivityRingPieChart(
                title: 'Calorías',
                current: _caloriesBurned * _animation.value,
                target: 800,
                color: AppTheme.moveRingColor,
                unit: 'kcal',
                size: 90,
              );
            },
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return ActivityRingPieChart(
                title: 'Pasos',
                current: _steps * _animation.value,
                target: 10000,
                color: Colors.blue,
                unit: 'pasos',
                size: 90,
              );
            },
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return ActivityRingPieChart(
                title: 'Distancia',
                current: _distance * _animation.value,
                target: 8,
                color: Colors.green,
                unit: 'km',
                size: 90,
              );
            },
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return ActivityRingPieChart(
                title: 'Activo',
                current: _activeMinutes * _animation.value,
                target: 60,
                color: Colors.amber,
                unit: 'min',
                size: 90,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B2F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _topTabController,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.5),
        indicator: BoxDecoration(
          color: AppTheme.moveRingColor,
          borderRadius: BorderRadius.circular(12),
        ),
        tabs: const [
          Tab(text: 'Resumen'),
          Tab(text: 'Actividad'),
          Tab(text: 'Progreso'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _topTabController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Cada pestaña se envuelve en SingleChildScrollView para permitir scroll interno
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _buildSummaryTab(),
        ),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _buildActivityTab(),
        ),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: _buildProgressTab(),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anillos de Actividad',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) {
                          return ProgressPieChart(
                            progress: 0.75 * _animation.value,
                            total: 1.0,
                            color: AppTheme.moveRingColor,
                            size: 150,
                          );
                        },
                      ),
                    ),
                    // Middle ring
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) {
                          return ProgressPieChart(
                            progress: 0.62 * _animation.value,
                            total: 1.0,
                            color: AppTheme.exerciseRingColor,
                            size: 120,
                          );
                        },
                      ),
                    ),
                    // Inner ring
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, _) {
                          return ProgressPieChart(
                            progress: 0.88 * _animation.value,
                            total: 1.0,
                            color: AppTheme.standRingColor,
                            size: 90,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRingLegend(
                      'Movimiento',
                      '${(_caloriesBurned * 0.75).toInt()} / $_caloriesBurned kcal',
                      AppTheme.moveRingColor,
                      0.75,
                    ),
                    const SizedBox(height: 16),
                    _buildRingLegend(
                      'Ejercicio',
                      '${(_activeMinutes * 0.62).toInt()} / $_activeMinutes min',
                      AppTheme.exerciseRingColor,
                      0.62,
                    ),
                    const SizedBox(height: 16),
                    _buildRingLegend(
                      'De pie',
                      '9 / 12 horas',
                      AppTheme.standRingColor,
                      0.88,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Entrenamiento', '45 min', Icons.fitness_center),
              _buildStatColumn('Sueño', '7h 24m', Icons.nightlight_round),
              _buildStatColumn('Energía', '1840 kcal', Icons.restaurant),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingLegend(
      String label, String value, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Stack(
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: MediaQuery.of(context).size.width *
                      0.4 *
                      progress *
                      _animation.value,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frecuencia Cardíaca',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Últimas 24 horas',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2B2F),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.white.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 40,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final hours = [
                              '12 AM',
                              '4 AM',
                              '8 AM',
                              '12 PM',
                              '4 PM',
                              '8 PM'
                            ];
                            if (value % 1 == 0 &&
                                value.toInt() %
                                        ((_heartRateData.length / 6).ceil()) ==
                                    0) {
                              final index =
                                  value ~/ ((_heartRateData.length / 6).ceil());
                              if (index < hours.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    hours[index.toInt()],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 10,
                                    ),
                                  ),
                                );
                              }
                            }
                            return const SizedBox();
                          },
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: _heartRateData.length - 1.0,
                    minY: 50,
                    maxY: 140,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _animation.value < 1
                            ? _heartRateData.sublist(
                                0,
                                (_heartRateData.length * _animation.value)
                                    .toInt()
                                    .clamp(1, _heartRateData.length))
                            : _heartRateData,
                        isCurved: true,
                        color: AppTheme.moveRingColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.moveRingColor.withOpacity(0.2),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            return LineTooltipItem(
                              '${touchedSpot.y.toInt()} bpm',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            );
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

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrenamientos Semanales',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B2F),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  // Create StackedWorkoutData from weekly workouts
                  final workoutData =
                      _weeklyWorkouts.asMap().entries.map((entry) {
                    final value = entry.value * _animation.value;
                    // Split the time into three workout types
                    final cardio = value * 0.4; // 40% cardio
                    final strength = value * 0.35; // 35% strength
                    final flexibility = value * 0.25; // 25% flexibility

                    return StackedWorkoutData(
                      xLabel: ['L', 'M', 'X', 'J', 'V', 'S', 'D'][entry.key],
                      values: [cardio, strength, flexibility],
                    );
                  }).toList();

                  return WorkoutStackedColumnChart(
                    workoutData: workoutData,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildWeeklyStat('Total', '20h', Icons.access_time),
                const SizedBox(width: 24),
                _buildWeeklyStat('Media', '2.8h/día', Icons.calendar_today),
                const SizedBox(width: 24),
                _buildWeeklyStat('Mejor', 'Viernes', Icons.emoji_events),
              ],
            ),
            const SizedBox(height: 24),
            // Fitness radar chart
            const Text(
              'Perfil de Capacidades',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2B2F),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  // Get sample data and multiply by animation value for effect
                  final data = FitnessRadarData.getSampleFitnessData();
                  final animatedData = data.map(
                      (key, value) => MapEntry(key, value * _animation.value));

                  return FitnessRadarChart(
                    fitnessAttributes: animatedData,
                    maxValue: 10.0,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBarColor(double value) {
    if (value >= 4) return AppTheme.moveRingColor;
    if (value >= 3) return Colors.amber;
    if (value >= 2) return Colors.green;
    return Colors.blue;
  }

  Widget _buildWeeklyStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingWorkouts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Próximos Entrenamientos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Ver más',
                  style: TextStyle(
                    color: AppTheme.moveRingColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 170,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _upcomingWorkouts.length,
            itemBuilder: (context, index) {
              final workout = _upcomingWorkouts[index];
              String imageKeyword;

              // Map workout image string to appropriate keyword
              switch (workout['image']) {
                case 'weights':
                  imageKeyword = 'Weightlifting';
                  break;
                case 'cardio':
                  imageKeyword = 'Running Training';
                  break;
                case 'stretching':
                  imageKeyword = 'Yoga Stretching';
                  break;
                default:
                  imageKeyword = 'Fitness Training';
              }

              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2B2F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        "https://images.unsplash.com/photo-1575361204480-aadea25e6e68?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w0NTYyMDF8MHwxfHJhbmRvbXx8fHx8fHx8fDE3NDM2NjkwOTd8&ixlib=rb-4.0.3&q=80&w=1080",
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          workout['duration'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white54,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workout['time'],
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.person,
                                  color: Colors.white54,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  workout['trainer'],
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 2, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
