import 'package:flutter/material.dart' hide BackButton;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_cubit.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_state.dart';
import 'package:IAEntrenar/core/ui/buttons.dart';

/// Opciones predefinidas de género.
const String _kGenderMale = 'hombre';
const String _kGenderFemale = 'mujer';
const String _kGenderOther = 'otro';

class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  State<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  /// Valor seleccionado: [_kGenderMale], [_kGenderFemale] o [_kGenderOther].
  String? _selectedOption;

  /// Texto personalizado cuando [_selectedOption] es [_kGenderOther].
  final TextEditingController _otherController = TextEditingController();
  final FocusNode _otherFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _otherController.dispose();
    _otherFocusNode.dispose();
    super.dispose();
  }

  /// Devuelve el valor final de género a guardar.
  String? get _genderValue {
    if (_selectedOption == null) return null;
    if (_selectedOption == _kGenderOther) {
      final text = _otherController.text.trim();
      return text.isEmpty ? null : text;
    }
    return _selectedOption;
  }

  void _handleContinue() async {
    final gender = _genderValue;
    if (gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Selecciona una opción o escribe con qué género te identificas',
          ),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }

    await context.read<OnboardingCubit>().saveStep(
          currentStep: 5,
          fields: {'gender': gender},
        );
    if (!mounted) return;
    context.goNamed('onboarding-step6');
  }

  void _handleBack() {
    context.goNamed('onboarding-step4');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, onboardingState) {
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
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
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
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
                      Text(
                        'Género',
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
                        'Selecciona con qué género te identificas',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                      SizedBox(height: size.height * 0.04),
                      _OptionCard(
                        label: 'Hombre',
                        value: _kGenderMale,
                        selected: _selectedOption == _kGenderMale,
                        onTap: () => setState(() => _selectedOption = _kGenderMale),
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 12),
                      _OptionCard(
                        label: 'Mujer',
                        value: _kGenderFemale,
                        selected: _selectedOption == _kGenderFemale,
                        onTap: () =>
                            setState(() => _selectedOption = _kGenderFemale),
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 350.ms)
                          .slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 12),
                      _OptionCard(
                        label: 'Otro',
                        value: _kGenderOther,
                        selected: _selectedOption == _kGenderOther,
                        onTap: () {
                          setState(() => _selectedOption = _kGenderOther);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _otherFocusNode.requestFocus();
                          });
                        },
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                      if (_selectedOption == _kGenderOther) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otherController,
                          focusNode: _otherFocusNode,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Escribe con qué género te identificas',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05, end: 0),
                      ],
                      SizedBox(height: size.height * 0.05),
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
                            context.read<OnboardingCubit>().saveStep(
                                  currentStep: 5,
                                  fields: {},
                                );
                            if (!context.mounted) return;
                            context.goNamed('onboarding-step6');
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

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withOpacity(0.25)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : Colors.white.withOpacity(0.2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.white.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
