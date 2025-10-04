import 'package:flutter/material.dart' hide BackButton;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/back_button.dart';

class TrainingGoalScreen extends StatefulWidget {
  const TrainingGoalScreen({Key? key}) : super(key: key);

  @override
  State<TrainingGoalScreen> createState() => _TrainingGoalScreenState();
}

class _TrainingGoalScreenState extends State<TrainingGoalScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedFrequency;
  String? _selectedGoal;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_selectedFrequency != null && _selectedGoal != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Actualizar los objetivos del usuario
      authProvider.setGoals([_selectedGoal!]);
      // Actualizar el nivel de entrenamiento basado en la frecuencia
      authProvider.setTrainingLevel(_selectedFrequency!);
      authProvider.nextOnboardingStep();
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una frecuencia y un objetivo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleBack() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.previousOnboardingStep();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background image with gradient overlay
          Positioned.fill(
            child: Image.network(
              "https://pixabay.com/get/gb79dd88e05560b3d0c9589d352adae2babae0835e735536f7305dfdbb51f6445026ea74d85fc27f6a9cb99e49e9bb877e6fc9cf48d3fb44a427f185fbfb4b133_1280.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Consumer<AuthProvider>(builder: (context, authProvider, _) {
                    return LinearProgressIndicator(
                      value: (authProvider.onboardingStep + 1) /
                          authProvider.totalOnboardingSteps,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 8,
                    )
                        .animate(controller: _animationController)
                        .fadeIn(duration: 400.ms)
                        .slideX(begin: -0.1, end: 0);
                  }),

                  SizedBox(height: 6),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackButton(
                      onPressed: _handleBack,
                      icon: Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.2, end: 0),

                  SizedBox(height: size.height * 0.02),

                  // Title - Training Frequency
                  Text(
                    '¿Con qué frecuencia entrenas?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Selecciona la opción que mejor refleje tus hábitos',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: size.height * 0.03),

                  // Training frequency options
                  SizedBox(
                    height: 210,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: OnboardingConstants.trainingFrequencies.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final frequency =
                            OnboardingConstants.trainingFrequencies[index];
                        return _buildFrequencyCard(
                          frequency,
                          _frequencyIcon(index),
                          frequency == _selectedFrequency,
                        )
                            .animate(controller: _animationController)
                            .fadeIn(
                                duration: 500.ms,
                                delay: 300.ms + (index * 100).ms)
                            .slideX(begin: 0.2, end: 0);
                      },
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Title - Fitness Goals
                  Text(
                    '¿Cuál es tu objetivo principal?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Selecciona tu objetivo de fitness principal',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 500.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: size.height * 0.03),

                  // Fitness goals grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: OnboardingConstants.fitnessGoals.length,
                    itemBuilder: (context, index) {
                      final goal = OnboardingConstants.fitnessGoals[index];
                      return _buildGoalCard(
                        goal,
                        _goalIcon(index),
                        goal == _selectedGoal,
                      )
                          .animate(controller: _animationController)
                          .fadeIn(
                              duration: 500.ms,
                              delay: 600.ms + (index * 100).ms)
                          .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0));
                    },
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Continue button
                  CustomButton(
                    text: 'Continuar',
                    onPressed: _handleContinue,
                    width: double.infinity,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 800.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  // Skip button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        authProvider.skipOnboarding();
                      },
                      child: Text(
                        'Omitir',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 900.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard(String frequency, IconData icon, bool isSelected) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFrequency = frequency;
        });
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color:
                        isSelected ? theme.colorScheme.primary : Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    frequency,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          isSelected ? theme.colorScheme.primary : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(String goal, IconData icon, bool isSelected) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goal;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color:
                        isSelected ? theme.colorScheme.primary : Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    goal,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          isSelected ? theme.colorScheme.primary : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Selected indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _frequencyIcon(int index) {
    switch (index) {
      case 0:
        return Icons.calendar_today; // Rarely
      case 1:
        return Icons.looks_one; // 1-2 times
      case 2:
        return Icons.looks_3; // 3-4 times
      case 3:
        return Icons.looks_5; // 5+ times
      case 4:
        return Icons.repeat; // Multiple times daily
      default:
        return Icons.fitness_center;
    }
  }

  IconData _goalIcon(int index) {
    switch (index) {
      case 0:
        return Icons.trending_down; // Lose weight
      case 1:
        return Icons.fitness_center; // Gain muscle
      case 2:
        return Icons.directions_run; // Improve endurance
      case 3:
        return Icons.accessibility_new; // Improve flexibility
      case 4:
        return Icons.favorite; // General maintenance
      default:
        return Icons.stars;
    }
  }
}
