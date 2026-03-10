import 'package:flutter/material.dart' hide BackButton;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_cubit.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_state.dart';
import 'package:IAEntrenar/core/constants/onboarding_constants.dart';
import 'package:IAEntrenar/core/ui/buttons.dart';

class HeightSelectionScreen extends StatefulWidget {
  const HeightSelectionScreen({super.key});

  @override
  State<HeightSelectionScreen> createState() => _HeightSelectionScreenState();
}

class _HeightSelectionScreenState extends State<HeightSelectionScreen>
    with SingleTickerProviderStateMixin {
  late FixedExtentScrollController _scrollController;
  late double _selectedHeight;
  late AnimationController _animationController;

  // Scrolling constants
  final double _itemExtent = 20.0;
  late int _totalItems;
  late double _minHeight;
  late double _maxHeight;

  @override
  void initState() {
    super.initState();
    _initializeHeightValues();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  void _initializeHeightValues() {
    _minHeight = OnboardingConstants.minHeightCm;
    _maxHeight = OnboardingConstants.maxHeightCm;
    _selectedHeight = OnboardingConstants.defaultHeightCm;

    // Calculate number of items (1 cm increments)
    _totalItems = (_maxHeight - _minHeight).round() + 1;

    // Initialize scroll controller positioned so that selected value is centered
    final initialIndex = (_maxHeight - _selectedHeight).round();
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _selectHeight(double height) {
    final index = (_maxHeight - height).round();
    _scrollController.animateToItem(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleContinue() async {
    await context.read<OnboardingCubit>().saveStep(
      currentStep: 1,
      fields: {'height': _selectedHeight},
    );
    if (!mounted) {
      return;
    }
    context.goNamed('onboarding-step2');
  }

  void _handleBack() {
    context.goNamed('onboarding-step0');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, onboardingState) {
        return Scaffold(
          body: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: (onboardingState.currentStep + 1) /
                            onboardingState.totalSteps,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 6),

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

                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cuál es tu estatura?',
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
                        'Para personalizar tu plan de entrenamiento',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),

                  // Height display and ruler
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selected height indicator
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 140, // ancho fijo para evitar cambios de tamaño
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25, vertical: 20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _selectedHeight.toStringAsFixed(0),
                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'cm',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate(controller: _animationController)
                                  .fadeIn(duration: 600.ms, delay: 400.ms)
                                  .scale(
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1.0, 1.0),
                                      curve: Curves.easeOut),
                            ],
                          ),
                        ),

                        // Height ruler
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Ruler
                                ListWheelScrollView.useDelegate(
                                  controller: _scrollController,
                                  itemExtent: _itemExtent,
                                  perspective: 0.00001, // Flat appearance
                                  physics: const FixedExtentScrollPhysics(),
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedHeight = _maxHeight - index;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    builder: (context, index) {
                                      final height = _maxHeight - index;
                                      final isMajor10 = height % 10 == 0; // cada 10 cm
                                      final isMid5 = height % 5 == 0 && !isMajor10; // cada 5 cm

                                      return GestureDetector(
                                        onTap: () => _selectHeight(height),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Tick mark
                                            Container(
                                              width: isMajor10
                                                  ? 40
                                                  : isMid5
                                                      ? 28
                                                      : 16,
                                              height: 2,
                                              color: isMajor10
                                                  ? Colors.white.withOpacity(0.9)
                                                  : isMid5
                                                      ? Colors.white.withOpacity(0.6)
                                                      : Colors.white.withOpacity(0.35),
                                            ),

                                            // Label
                                            if (isMajor10)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0),
                                                child: Text(
                                                  height.toStringAsFixed(0),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: (height - _selectedHeight).abs() < 0.01
                                                        ? theme.colorScheme.primary
                                                        : Colors.white.withOpacity(0.7),
                                                    fontWeight: (height - _selectedHeight).abs() < 0.01
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                    childCount: _totalItems,
                                  ),
                                ),

                                // Center indicator
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(1.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 600.ms, delay: 500.ms),
                        ),
                      ],
                    ),
                  ),

                  // Continue button
                  CustomButton(
                    text: 'Continuar',
                    onPressed: _handleContinue,
                    width: double.infinity,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        context.read<OnboardingCubit>().completeOnboarding();
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
                      .fadeIn(duration: 600.ms, delay: 700.ms),
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
}
