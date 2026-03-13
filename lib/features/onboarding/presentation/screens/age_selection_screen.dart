import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_cubit.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_state.dart';
import 'package:IAEntrenar/core/constants/onboarding_constants.dart';
import 'package:IAEntrenar/core/ui/buttons.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({super.key});

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late FixedExtentScrollController _scrollController;
  late int _selectedAge;
  late AnimationController _animationController;

  // Item size constants
  final double _itemExtent = 70.0;
  final int _totalItems =
      OnboardingConstants.maxAge - OnboardingConstants.minAge + 1;

  @override
  void initState() {
    super.initState();
    _selectedAge = OnboardingConstants.defaultAge;

    final initialIndex = _selectedAge - OnboardingConstants.minAge;
    _scrollController = FixedExtentScrollController(initialItem: initialIndex);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _selectAge(int age) {
    final index = age - OnboardingConstants.minAge;
    _scrollController.animateToItem(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleContinue() async {
    await context.read<OnboardingCubit>().saveStep(
      currentStep: 0,
      fields: {'age': _selectedAge},
    );
    if (!mounted) {
      return;
    }
    context.goNamed('onboarding-step1');
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

                  SizedBox(height: size.height * 0.06),

                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cual es tu edad?',
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
                        'Esto nos ayudaria a personalizar tu plan de entrenamiento',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),

                  SizedBox(height: size.height * 0.08),

                  // Selected age indicator
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _selectedAge.toString(),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                        .animate(controller: _animationController)
                        .fadeIn(duration: 600.ms, delay: 300.ms)
                        .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.0, 1.0),
                            curve: Curves.elasticOut),
                  ),

                  SizedBox(height: size.height * 0.06),

                  // Age selector (center-based selection)
                  SizedBox(
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ruler
                        RotatedBox(
                          quarterTurns: -1,
                          child: ListWheelScrollView.useDelegate(
                            controller: _scrollController,
                            itemExtent: _itemExtent,
                            perspective: 0.00001,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _selectedAge = OnboardingConstants.minAge + index;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                final age = OnboardingConstants.minAge + index;
                                final isSelected = age == _selectedAge;

                                return RotatedBox(
                                  quarterTurns: 1,
                                  child: GestureDetector(
                                    onTap: () => _selectAge(age),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 5),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Age marker
                                          Container(
                                            width: 4,
                                            height: isSelected ? 40 : 20,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? theme.colorScheme.primary
                                                  : Colors.white.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          // Age number
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 300),
                                            style: isSelected
                                                ? theme.textTheme.titleLarge!.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.primary,
                                                  )
                                                : theme.textTheme.bodyLarge!.copyWith(
                                                    color: Colors.white.withOpacity(0.5),
                                                  ),
                                            child: Text(
                                              age.toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _totalItems,
                            ),
                          ),
                        ),

                        // Gradient shadows on sides to indicate continuity
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withOpacity(0),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: [
                                  Colors.black.withOpacity(0),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 400.ms),

                  const Spacer(),

                  // Continue button
                  CustomButton(
                    text: 'Continuar',
                    onPressed: _handleContinue,
                    width: double.infinity,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 500.ms)
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
                      .fadeIn(duration: 600.ms, delay: 600.ms),
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
