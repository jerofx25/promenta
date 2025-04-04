import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class AgeSelectionScreen extends StatefulWidget {
  const AgeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<AgeSelectionScreen> createState() => _AgeSelectionScreenState();
}

class _AgeSelectionScreenState extends State<AgeSelectionScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late int _selectedAge;
  late AnimationController _animationController;

  // Item size constants
  final double _itemWidth = 70.0;
  final double _itemExtent = 70.0;
  final int _totalItems =
      OnboardingConstants.maxAge - OnboardingConstants.minAge + 1;

  @override
  void initState() {
    super.initState();
    _selectedAge = OnboardingConstants.defaultAge;
    _scrollController = ScrollController(
      initialScrollOffset:
          (_selectedAge - OnboardingConstants.minAge) * _itemWidth,
    );

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
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _selectAge(int age) {
    setState(() {
      _selectedAge = age;
    });

    // Scroll to the selected age with animation
    _scrollController.animateTo(
      (age - OnboardingConstants.minAge) * _itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleContinue() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setAge(_selectedAge);
    authProvider.nextOnboardingStep();
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
              "https://pixabay.com/get/g66f4ecb7d502497509b559223ca0013a81b02f30929c58668989243cc4b7400a87b89c4576ccc87a48d8eeb8bb9c5f5d74e50d83fee80e3efeae6c5094150f66_1280.jpg",
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
            child: Padding(
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

                  // Age selector
                  Container(
                    height: 100,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          // Calculate the selected age based on the current scroll position
                          final offset = _scrollController.offset;
                          final index = (offset / _itemWidth).round();
                          final age = OnboardingConstants.minAge + index;

                          // Only update if the selected age has changed
                          if (age != _selectedAge) {
                            _selectAge(age);
                          }
                        }
                        return true;
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _totalItems,
                        itemExtent: _itemExtent,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final age = OnboardingConstants.minAge + index;
                          final isSelected = age == _selectedAge;

                          return GestureDetector(
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
                                            color:
                                                Colors.white.withOpacity(0.5),
                                          ),
                                    child: Text(
                                      age.toString(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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
                      .fadeIn(duration: 600.ms, delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
