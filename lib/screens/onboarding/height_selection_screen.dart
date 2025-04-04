import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class HeightSelectionScreen extends StatefulWidget {
  const HeightSelectionScreen({Key? key}) : super(key: key);

  @override
  State<HeightSelectionScreen> createState() => _HeightSelectionScreenState();
}

class _HeightSelectionScreenState extends State<HeightSelectionScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late double _selectedHeight;
  late AnimationController _animationController;
  String _unit = 'cm'; // Default unit is cm

  // Scrolling constants
  final double _itemHeight = 50.0;
  final double _itemExtent = 50.0;
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
    if (_unit == 'cm') {
      _minHeight = OnboardingConstants.minHeightCm;
      _maxHeight = OnboardingConstants.maxHeightCm;
      _selectedHeight = OnboardingConstants.defaultHeightCm;
    } else {
      _minHeight = OnboardingConstants.minHeightFt;
      _maxHeight = OnboardingConstants.maxHeightFt;
      _selectedHeight = OnboardingConstants.defaultHeightFt;
    }

    // Calculate number of items
    // For cm, use 1 cm increments
    // For ft, use 0.1 ft increments
    if (_unit == 'cm') {
      _totalItems = (_maxHeight - _minHeight).round() + 1;
    } else {
      _totalItems = ((_maxHeight - _minHeight) * 10).round() + 1;
    }

    // Initialize scroll controller with middle position
    final initialPosition;
    if (_unit == 'cm') {
      initialPosition = (_maxHeight - _selectedHeight) * _itemHeight;
    } else {
      initialPosition = (_maxHeight - _selectedHeight) * 10 * _itemHeight;
    }
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
    final oldValue = _selectedHeight;
    setState(() {
      // Toggle between cm and ft
      if (_unit == 'cm') {
        _unit = 'ft';
        // Convert cm to ft (1cm = 0.0328084ft)
        _selectedHeight =
            double.parse((oldValue * 0.0328084).toStringAsFixed(1));
      } else {
        _unit = 'cm';
        // Convert ft to cm (1ft = 30.48cm)
        _selectedHeight = double.parse((oldValue * 30.48).toStringAsFixed(0));
      }
    });

    // Reinitialize with new unit
    _scrollController.dispose();
    _initializeHeightValues();

    // Need to wait for the next frame for the scroll controller to be attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position;
        if (_unit == 'cm') {
          position = (_maxHeight - _selectedHeight) * _itemHeight;
        } else {
          position = (_maxHeight - _selectedHeight) * 10 * _itemHeight;
        }
        _scrollController.jumpTo(position);
      }
    });
  }

  void _selectHeight(double height) {
    setState(() {
      _selectedHeight = height;
    });

    // Scroll to the selected height with animation
    final position;
    if (_unit == 'cm') {
      position = (_maxHeight - height) * _itemHeight;
    } else {
      position = (_maxHeight - height) * 10 * _itemHeight;
    }

    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleContinue() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setHeight(_selectedHeight, _unit);
    authProvider.nextOnboardingStep();
  }

  void _handleBack() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.previousOnboardingStep();
  }

  // Convert height to display format
  String _getDisplayHeight() {
    if (_unit == 'cm') {
      return _selectedHeight.toStringAsFixed(0);
    } else {
      // Convert to feet and inches format (e.g., 5'10")
      final totalFeet = _selectedHeight;
      final feet = totalFeet.floor();
      final inches = ((totalFeet - feet) * 12).round();
      return "$feet'$inches\"";
    }
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
              "https://pixabay.com/get/ge77ca451695aba2c4a90cb363671435eb0dcc7ab65afeb21e3d9353fcd6b5130e3f5948b2e1f663bb1b7e6a35101b0d81ce85f21374841b801c70efa52ebbb08_1280.jpg",
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

                  SizedBox(height: size.height * 0.02),

                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cual es tu estatura?',
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

                  // Height unit toggle
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildUnitToggle('cm', _unit == 'cm'),
                          const SizedBox(width: 20),
                          _buildUnitToggle('ft', _unit == 'ft'),
                        ],
                      ),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 300.ms),

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
                                      _getDisplayHeight(),
                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      _unit,
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
                            child: Stack(
                              children: [
                                // Ruler
                                NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    if (notification is ScrollEndNotification) {
                                      // Calculate the selected height based on the current scroll position
                                      final offset = _scrollController.offset;
                                      double height;

                                      if (_unit == 'cm') {
                                        height =
                                            _maxHeight - (offset / _itemHeight);
                                        height = double.parse(
                                            height.toStringAsFixed(0));
                                      } else {
                                        height = _maxHeight -
                                            (offset / _itemHeight / 10);
                                        height = double.parse(
                                            height.toStringAsFixed(1));
                                      }

                                      // Only update if the selected height has changed
                                      if ((height - _selectedHeight).abs() >
                                          0.01) {
                                        setState(() {
                                          _selectedHeight = height;
                                        });
                                      }
                                    }
                                    return true;
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ListView.builder(
                                        controller: _scrollController,
                                        reverse: true,
                                        itemCount: _totalItems,
                                        itemExtent: _itemExtent,
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          double height;
                                          bool showLabel = false;

                                          if (_unit == 'cm') {
                                            height = _minHeight + index;
                                            // Show label every 5 cm
                                            showLabel = height % 5 == 0;
                                          } else {
                                            height = _minHeight + (index / 10);
                                            // Show label every 0.5 foot
                                            showLabel =
                                                (height * 10).round() % 5 == 0;
                                          }

                                          return GestureDetector(
                                            onTap: () => _selectHeight(height),
                                            child: Row(
                                              children: [
                                                // Tick mark
                                                Container(
                                                  width: showLabel ? 35 : 20,
                                                  height: 2,
                                                  color: showLabel
                                                      ? Colors.white
                                                          .withOpacity(0.8)
                                                      : Colors.white
                                                          .withOpacity(0.3),
                                                ),

                                                // Label
                                                if (showLabel)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0),
                                                    child: Text(
                                                      _unit == 'cm'
                                                          ? height
                                                              .toStringAsFixed(
                                                                  0)
                                                          : height
                                                              .toStringAsFixed(
                                                                  1),
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: (height -
                                                                        _selectedHeight)
                                                                    .abs() <
                                                                0.01
                                                            ? theme.colorScheme
                                                                .primary
                                                            : Colors.white
                                                                .withOpacity(
                                                                    0.6),
                                                        fontWeight:
                                                            (height - _selectedHeight)
                                                                        .abs() <
                                                                    0.01
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
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
                                                  color:
                                                      theme.colorScheme.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          1.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Gradient shadows on top and bottom
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        height: 60,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.8),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        height: 60,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.8),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
