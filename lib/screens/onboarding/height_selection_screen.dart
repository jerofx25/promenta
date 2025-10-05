import 'package:flutter/material.dart' hide BackButton;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/back_button.dart';

class HeightSelectionScreen extends StatefulWidget {
  const HeightSelectionScreen({super.key});

  @override
  State<HeightSelectionScreen> createState() => _HeightSelectionScreenState();
}

class _HeightSelectionScreenState extends State<HeightSelectionScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late double _selectedHeight;
  late final TextEditingController _heightController;
  late final FocusNode _heightFocusNode;
  late AnimationController _animationController;

  // Scrolling constants (más denso: 1 cm por item)
  final double _itemHeight = 20.0;
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
    _heightController =
        TextEditingController(text: _selectedHeight.toStringAsFixed(0));
    _heightFocusNode = FocusNode();

    // Calculate number of items (1 cm increments)
    _totalItems = (_maxHeight - _minHeight).round() + 1;

    // Initialize scroll controller positioned so that selected value is centered
    final initialPosition = (_selectedHeight - _minHeight) * _itemHeight;
    _scrollController = ScrollController(initialScrollOffset: initialPosition);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heightController.dispose();
    _heightFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _selectHeight(double height) {
    setState(() {
      _selectedHeight = height;
    });
    if (!_heightFocusNode.hasFocus) {
      _heightController.text = _selectedHeight.toStringAsFixed(0);
    }

    // Scroll to the selected height with animation
    final position = (_maxHeight - height) * _itemHeight;

    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _applyTypedHeight(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) {
      // Restaurar valor actual si input inválido
      _heightController.text = _selectedHeight.toStringAsFixed(0);
      return;
    }
    final clamped = parsed.clamp(_minHeight, _maxHeight).roundToDouble();
    setState(() {
      _selectedHeight = clamped;
      _heightController.text = _selectedHeight.toStringAsFixed(0);
    });
    final position = (_selectedHeight - _minHeight) * _itemHeight;
    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    _heightFocusNode.unfocus();
  }

  void _handleContinue() {
    // Calcular índice centrado en el viewport
    final viewport = _scrollController.position.viewportDimension;
    final centerPosition = _scrollController.offset + viewport / 2;
    int index = ((centerPosition - _itemExtent / 2) / _itemExtent).round();
    index = index.clamp(0, _totalItems - 1);
    final rounded = _minHeight + index;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setHeight(rounded);
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
          // Fondo limpio: sin imagen ni overlay

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
                                width:
                                    140, // ancho fijo para evitar cambios de tamaño
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
                                    TextField(
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3)
                                      ],
                                      controller: _heightController,
                                      focusNode: _heightFocusNode,
                                      textAlign: TextAlign.center,
                                      onChanged: (value) {
                                        // Solo actualizar cuando se complete el último valor
                                        if (value.length == 3) {
                                          _applyTypedHeight(value);
                                        }
                                      },
                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        isCollapsed: true,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: _applyTypedHeight,
                                      onEditingComplete: () =>
                                          _applyTypedHeight(
                                              _heightController.text),
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
                              children: [
                                // Ruler
                                NotificationListener<ScrollNotification>(
                                  onNotification: (notification) {
                                    // Actualiza el valor mostrado según el centro mientras se arrastra
                                    final offset = _scrollController.offset;
                                    final heightCentered =
                                        _minHeight + (offset / _itemHeight);
                                    final rounded = double.parse(
                                        heightCentered.toStringAsFixed(0));

                                    if (notification
                                        is ScrollUpdateNotification) {
                                      if ((rounded - _selectedHeight).abs() >
                                          0.01) {
                                        setState(() {
                                          _selectedHeight = rounded;
                                          _heightController.text =
                                              rounded.toStringAsFixed(0);
                                        });
                                      }
                                    }

                                    if (notification is ScrollEndNotification) {
                                      // Snap al múltiplo más cercano cuando termina el scroll
                                      final targetOffset =
                                          (rounded - _minHeight) * _itemHeight;
                                      if ((offset - targetOffset).abs() > 0.5) {
                                        _scrollController.animateTo(
                                          targetOffset,
                                          duration:
                                              const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                        );
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
                                          final height = _minHeight + index;
                                          final isMajor10 =
                                              height % 10 == 0; // cada 10 cm
                                          final isMid5 = height % 5 == 0 &&
                                              !isMajor10; // cada 5 cm

                                          return GestureDetector(
                                            onTap: () => _selectHeight(height),
                                            child: Row(
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
                                                      ? Colors.white
                                                          .withOpacity(0.9)
                                                      : isMid5
                                                          ? Colors.white
                                                              .withOpacity(0.6)
                                                          : Colors.white
                                                              .withOpacity(
                                                                  0.35),
                                                ),

                                                // Label
                                                if (isMajor10)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0),
                                                    child: Text(
                                                      height.toStringAsFixed(0),
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
                                                                    0.7),
                                                        fontWeight:
                                                            (height - _selectedHeight)
                                                                        .abs() <
                                                                    0.01
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .w500,
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

                                      // Sombras removidas
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
}
