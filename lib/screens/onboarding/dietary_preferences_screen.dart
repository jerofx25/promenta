import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';


class DietaryPreferencesScreen extends StatefulWidget {
  const DietaryPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<DietaryPreferencesScreen> createState() => _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState extends State<DietaryPreferencesScreen> with SingleTickerProviderStateMixin {
  final Set<String> _selectedDiets = {};
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

  void _toggleDiet(String diet) {
    setState(() {
      if (_selectedDiets.contains(diet)) {
        _selectedDiets.remove(diet);
      } else {
        _selectedDiets.add(diet);
      }
    });
  }

  void _handleContinue() {
    if (_selectedDiets.isEmpty) {
      // Show error message if no diet is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos una preferencia dietética'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setDietaryHabits(_selectedDiets.toList());
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
              "https://pixabay.com/get/g842eb985ae1233fbe19c2227f4426c4603dc669f08bc2e9ac82e9e25a4700472597b669ff11df9b6cef09f421d1eb950da90f7f250cf0248df7050e7877eb70e_1280.jpg",
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
                      value: (authProvider.onboardingStep + 1) / authProvider.totalOnboardingSteps,
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
                  Text(
                    'Preferencias dietéticas',
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
                    'Selecciona tus hábitos alimenticios (puedes elegir varios)',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                  .animate(controller: _animationController)
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),
                  
                  SizedBox(height: size.height * 0.03),
                  
                  // Grid of dietary options
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: OnboardingConstants.dietaryHabits.length,
                    itemBuilder: (context, index) {
                      final diet = OnboardingConstants.dietaryHabits[index];
                      final isSelected = _selectedDiets.contains(diet);
                      return _buildDietCard(
                        diet,
                        _dietIcon(index),
                        isSelected,
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
                  
                  // Skip button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
  
  Widget _buildDietCard(String diet, IconData icon, bool isSelected, int index) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _toggleDiet(diet),
      child: Container(
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
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.white,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diet,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
    )
    .animate(controller: _animationController)
    .fadeIn(duration: 500.ms, delay: 300.ms + (index * 50).ms)
    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
  }
  
  IconData _dietIcon(int index) {
    switch (index) {
      case 0: return Icons.restaurant; // Omnivore
      case 1: return Icons.grass; // Vegetarian
      case 2: return Icons.spa; // Vegan
      case 3: return Icons.egg_alt; // Keto
      case 4: return Icons.forest; // Paleo
      case 5: return Icons.bakery_dining; // Gluten-free
      case 6: return Icons.local_drink; // Dairy-free
      case 7: return Icons.hourglass_empty; // Intermittent fasting
      case 8: return Icons.rice_bowl; // Low-carb
      case 9: return Icons.fitness_center; // High-protein
      default: return Icons.restaurant_menu;
    }
  }
}