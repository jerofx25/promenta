import 'package:flutter/material.dart' hide BackButton;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/back_button.dart';

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({Key? key}) : super(key: key);

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen>
    with SingleTickerProviderStateMixin {
  bool _hasSelectedImage = false;
  String? _imageUrl;
  late AnimationController _animationController;
  bool _isLoading = false;

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

  Future<void> _takePicture() async {
    // In a real app, this would use camera plugin
    // For this demo, we'll simulate selecting an image
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _hasSelectedImage = true;
      _imageUrl =
          "https://pixabay.com/get/g1d3f3794e44fba15083c2eca84405f0b2421cb09110dcf3093ce70aaa770d5a3407a98728c02de054d0422bb9f6d23387a041896bf01ae56b896ccaacecc4ced_1280.jpg";
      _isLoading = false;
    });
  }

  Future<void> _selectFromGallery() async {
    // In a real app, this would use image_picker plugin
    // For this demo, we'll simulate selecting an image
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _hasSelectedImage = true;
      _imageUrl =
          "https://pixabay.com/get/g27293d196a0c6534cafee9a4975b3509c2a80f7e4529385a809bdf3b0abd7c29c4b452f81c897db2cad0f289195e454d4b48a9168e8a98922fddb6af2b180132_1280.jpg";
      _isLoading = false;
    });
  }

  void _handleContinue() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_hasSelectedImage && _imageUrl != null) {
      authProvider.setPhotoUrl(_imageUrl!);
    }
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
              "https://pixabay.com/get/g9fb3762edd14b2077499d35413901477d8748a6d5d4404b44c1dcf988bd237f20b24d0024e9a617632c567b3302260a44c199024a3a919ba22ecd3643f992e62_1280.jpg",
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

                  // Title
                  Text(
                    'Foto de Perfil',
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
                    'Añade una foto para personalizar tu perfil y seguir tu progreso',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: size.height * 0.04),

                  // Photo section
                  Center(
                    child: _hasSelectedImage
                        ? _buildSelectedPhoto()
                        : _buildPhotoPlaceholder(),
                  ),

                  SizedBox(height: size.height * 0.04),

                  // Photo selection buttons
                  if (!_hasSelectedImage)
                    _buildPhotoSelectionButtons()
                        .animate(controller: _animationController)
                        .fadeIn(duration: 500.ms, delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                  // Why we need the photo section
                  if (!_hasSelectedImage)
                    _buildInfoSection()
                        .animate(controller: _animationController)
                        .fadeIn(duration: 500.ms, delay: 500.ms),

                  SizedBox(height: size.height * 0.04),

                  // Continue button
                  CustomButton(
                    text: _hasSelectedImage ? 'Continuar' : 'Omitir por ahora',
                    onPressed: _handleContinue,
                    width: double.infinity,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                  if (_hasSelectedImage) ...[
                    const SizedBox(height: 16),

                    // Retake photo button
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _hasSelectedImage = false;
                            _imageUrl = null;
                          });
                        },
                        icon: Icon(
                          Icons.refresh,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        label: Text(
                          'Volver a tomar foto',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms),
                  ],
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedPhoto() {
    final theme = Theme.of(context);

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          _imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: theme.colorScheme.primary,
              ),
            );
          },
        ),
      ),
    )
        .animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPhotoPlaceholder() {
    final theme = Theme.of(context);

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(
        Icons.add_a_photo,
        size: 64,
        color: Colors.white.withOpacity(0.7),
      ),
    )
        .animate(controller: _animationController)
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            curve: Curves.easeOut);
  }

  Widget _buildPhotoSelectionButtons() {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Take photo button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _takePicture,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Cámara'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Gallery button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galería'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '¿Por qué añadir una foto?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.compare_arrows,
            text: 'Comparar tu progreso con el tiempo',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.verified_user,
            text: 'Personalización de tu perfil',
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            icon: Icons.lock,
            text: 'Tu foto es privada y segura',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ],
    );
  }
}
