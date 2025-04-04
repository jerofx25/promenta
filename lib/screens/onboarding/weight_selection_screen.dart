import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class WeightSelectionScreen extends StatefulWidget {
  const WeightSelectionScreen({Key? key}) : super(key: key);

  @override
  State<WeightSelectionScreen> createState() => _WeightSelectionScreenState();
}

class _WeightSelectionScreenState extends State<WeightSelectionScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late double _selectedWeight;
  late AnimationController _animationController;
  String _unit = 'kg'; // Default unit is kg

  // Scrolling constants
  final double _itemWidth = 60.0;
  final double _itemExtent = 60.0;
  late int _totalItems;
  late double _minWeight;
  late double _maxWeight;

  @override
  void initState() {
    super.initState();
    _initializeWeightValues();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  void _initializeWeightValues() {
    if (_unit == 'kg') {
      _minWeight = OnboardingConstants.minWeightKg;
      _maxWeight = OnboardingConstants.maxWeightKg;
      _selectedWeight = OnboardingConstants.defaultWeightKg;
    } else {
      _minWeight = OnboardingConstants.minWeightLbs;
      _maxWeight = OnboardingConstants.maxWeightLbs;
      _selectedWeight = OnboardingConstants.defaultWeightLbs;
    }

    // Calculate number of items with 0.5 increments
    _totalItems = ((_maxWeight - _minWeight) * 2).round() + 1;

    // Initialize scroll controller with middle position
    final initialPosition = (_selectedWeight - _minWeight) * 2 * _itemWidth;
    _scrollController = ScrollController(
      initialScrollOffset: initialPosition,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleUnit() {
    final oldValue = _selectedWeight;
    setState(() {
      // Toggle between kg and lbs
      if (_unit == 'kg') {
        _unit = 'lbs';
        // Convert kg to lbs (1kg = 2.20462lbs)
        _selectedWeight = double.parse((oldValue * 2.20462).toStringAsFixed(1));
      } else {
        _unit = 'kg';
        // Convert lbs to kg (1lbs = 0.453592kg)
        _selectedWeight =
            double.parse((oldValue * 0.453592).toStringAsFixed(1));
      }
    });

    // Reinitialize with new unit
    _scrollController.dispose();
    _initializeWeightValues();

    // Need to wait for the next frame for the scroll controller to be attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController
            .jumpTo((_selectedWeight - _minWeight) * 2 * _itemWidth);
      }
    });
  }

  void _selectWeight(double weight) {
    setState(() {
      _selectedWeight = weight;
    });

    // Scroll to the selected weight with animation
    _scrollController.animateTo(
      (weight - _minWeight) * 2 * _itemWidth,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleContinue() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setWeight(_selectedWeight, _unit);
    authProvider.nextOnboardingStep();
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
              "https://pixabay.com/get/gd6bb39fbc35678a86de626dbf7016d880f6815bfb46ff31c02127b115d179d755e7b3cade205a0a6e2fdeef5510809582f19d3b4de309507ba88db5e34b6d1b7_1280.jpg",
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

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _handleBack,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: -0.2, end: 0),

                  SizedBox(height: size.height * 0.04),

                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cual es tu peso?',
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
                        'Esto nos ayudaria a calcular tus necesidades caloricas',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )
                          .animate(controller: _animationController)
                          .fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),

                  SizedBox(height: size.height * 0.06),

                  // Weight unit toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildUnitToggle('kg', _unit == 'kg'),
                      const SizedBox(width: 20),
                      _buildUnitToggle('lbs', _unit == 'lbs'),
                    ],
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 300.ms),

                  SizedBox(height: size.height * 0.05),

                  // Selected weight indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedWeight.toStringAsFixed(1),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _unit,
                            style: theme.textTheme.titleLarge?.copyWith(
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
                  ),

                  SizedBox(height: size.height * 0.06),

                  // Weight ruler
                  Container(
                    height: 120,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          // Calculate the selected weight based on the current scroll position
                          final offset = _scrollController.offset;
                          final index = (offset / _itemWidth).round();
                          final weight = _minWeight + (index / 2);

                          // Only update if the selected weight has changed
                          if ((weight - _selectedWeight).abs() > 0.01) {
                            setState(() {
                              _selectedWeight =
                                  double.parse(weight.toStringAsFixed(1));
                            });
                          }
                        }
                        return true;
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Center indicator
                          Container(
                            width: 2,
                            height: 50,
                            color: theme.colorScheme.primary,
                          ),

                          // Ruler
                          ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: _totalItems,
                            itemExtent: _itemExtent,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final weight = _minWeight + (index / 2);
                              final isWhole = weight.toInt() == weight;

                              return GestureDetector(
                                onTap: () => _selectWeight(weight),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Tick mark
                                      Container(
                                        width: 2,
                                        height: isWhole ? 40 : 25,
                                        color: isWhole
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.white.withOpacity(0.3),
                                      ),

                                      const SizedBox(height: 8),

                                      // Value label (only show for whole numbers)
                                      if (isWhole)
                                        Text(
                                          weight.toInt().toString(),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: weight ==
                                                    _selectedWeight
                                                        .roundToDouble()
                                                ? theme.colorScheme.primary
                                                : Colors.white.withOpacity(0.5),
                                            fontWeight: weight ==
                                                    _selectedWeight
                                                        .roundToDouble()
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Gradient shadows on sides to indicate continuity
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
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
                            width: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 500.ms),

                  const Spacer(),

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
                      .fadeIn(duration: 600.ms, delay: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(String unit, bool isSelected) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _toggleUnit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          unit.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
