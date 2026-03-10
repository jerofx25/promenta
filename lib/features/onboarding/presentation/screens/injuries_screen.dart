import 'package:flutter/material.dart' hide BackButton;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_cubit.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_state.dart';
import 'package:IAEntrenar/core/constants/onboarding_constants.dart';
import 'package:IAEntrenar/core/ui/buttons.dart';

class InjuriesScreen extends StatefulWidget {
  const InjuriesScreen({super.key});

  @override
  State<InjuriesScreen> createState() => _InjuriesScreenState();
}

class _InjuriesScreenState extends State<InjuriesScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedInjuries = {};
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

  void _toggleInjury(String injury) {
    setState(() {
      if (injury == 'Ninguna lesión') {
        if (_selectedInjuries.contains('Ninguna lesión')) {
          // Si ya estaba seleccionada y la tocan, la quitamos (dejando la lista vacía)
          _selectedInjuries.remove('Ninguna lesión');
        } else {
          // Si no estaba seleccionada, limpiamos todo y dejamos solo esa
          _selectedInjuries.clear();
          _selectedInjuries.add(injury);
        }
      } else {
        // Si selecciona cualquier otra lesión, quitamos "Ninguna lesión"
        _selectedInjuries.remove('Ninguna lesión');
        
        if (_selectedInjuries.contains(injury)) {
          _selectedInjuries.remove(injury);
        } else {
          _selectedInjuries.add(injury);
        }
      }
    });
  }

  void _handleContinue() async {
    // If "No injuries" is selected, clear any other selections
    if (_selectedInjuries.contains('Ninguna lesión')) {
      _selectedInjuries.clear();
      _selectedInjuries.add('Ninguna lesión');
    }
    await context.read<OnboardingCubit>().saveStep(
      currentStep: 3,
      fields: {'injuries': _selectedInjuries.toList()},
    );
    if (!mounted) {
      return;
    }
    context.goNamed('onboarding-step4');
  }

  void _handleBack() {
    context.goNamed('onboarding-step2');
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
                  Text(
                    '¿Tienes alguna lesion?',
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
                    'Selecciona las lesiones o condiciones que debemos tener en cuenta',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: size.height * 0.03),

                  // Injuries list
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: OnboardingConstants.commonInjuries.length,
                    itemBuilder: (context, index) {
                      final injury = OnboardingConstants.commonInjuries[index];
                      final isSelected = _selectedInjuries.contains(injury);
                      final isNoInjuries = injury == 'Ninguna lesión';

                      // If "No injuries" is selected, disable all other options
                      final isDisabled = isNoInjuries
                          ? false
                          : _selectedInjuries.contains('Ninguna lesión');

                      return _buildInjuryItem(
                        injury,
                        isSelected,
                        isDisabled,
                        index,
                      );
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
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            context
                                .read<OnboardingCubit>()
                                .completeOnboarding();
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

  Widget _buildInjuryItem(
      String injury, bool isSelected, bool isDisabled, int index) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => _toggleInjury(injury),
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Checkbox
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.white.withOpacity(0.6),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),

                  const SizedBox(width: 16),

                  // Injury name
                  Expanded(
                    child: Text(
                      injury,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),

                  // Icon for "No injuries"
                  if (injury == 'Ninguna lesión')
                    Icon(
                      Icons.thumb_up,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.white.withOpacity(0.6),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(controller: _animationController)
        .fadeIn(duration: 500.ms, delay: 300.ms + (index * 50).ms)
        .slideY(begin: 0.2, end: 0);
  }
}
