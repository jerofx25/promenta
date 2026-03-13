import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart' hide BackButton;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_cubit.dart';
import 'package:IAEntrenar/blocs/onboarding/onboarding_state.dart';
import 'package:IAEntrenar/core/ui/buttons.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';
import 'package:IAEntrenar/core/ui/pending_profile_snackbar.dart';
import 'package:IAEntrenar/core/ui/sleek_spinner.dart';
import 'package:IAEntrenar/repositories/auth_repository.dart';

/// Texto del selector de fotos en español.
class _SpanishAssetPickerTextDelegate extends EnglishAssetPickerTextDelegate {
  const _SpanishAssetPickerTextDelegate();

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get goToSystemSettings => 'Ir a configuración';

  @override
  String get accessLimitedAssets => 'Continuar con acceso limitado';

  @override
  String get unableToAccessAll =>
      'No se puede acceder a todos los archivos. Ve a configuración del sistema.';
}

/// Controller que difiere [forward] al siguiente frame solo durante build,
/// para evitar setState/markNeedsBuild cuando flutter_animate llama forward() en didUpdateWidget.
class _DeferredForwardController extends AnimationController {
  _DeferredForwardController({
    required super.vsync,
    required super.duration,
  });

  @override
  TickerFuture forward({double? from}) {
    final inBuild = SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks;
    if (inBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isAnimating && status != AnimationStatus.completed) {
          super.forward(from: from);
        }
      });
      return TickerFuture.complete();
    }
    return super.forward(from: from);
  }
}

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen>
    with TickerProviderStateMixin {
  bool _hasSelectedImage = false;
  String? _imageUrl;
  File? _selectedFile;
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = _DeferredForwardController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_animationController.isAnimating &&
          _animationController.status != AnimationStatus.completed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      await InstaAssetPicker.pickAssets(
        context,
        maxAssets: 1,
        pickerConfig: InstaAssetPickerConfig(
          textDelegate: const _SpanishAssetPickerTextDelegate(),
          closeOnComplete: true,
        ),
        onCompleted: (Stream<InstaAssetsExportDetails> exportDetails) {
          exportDetails.listen((details) {
            if (details.data.isNotEmpty && details.data.first.croppedFile != null) {
              final file = details.data.first.croppedFile!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedFile = file;
                    _hasSelectedImage = true;
                    _imageUrl = file.path;
                  });
                }
              });
            }
          });
        },
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        AppAlerts.showError(
          context,
          'No se pudo acceder a la galería. Por favor, verifica los permisos en la configuración de tu dispositivo.',
        );
      }
    }
  }

  void _handleContinue() async {
    // Marcar antes de completeOnboarding: el redirect (por routerNotifier.refresh())
    // puede navegar a Home antes de que lleguemos a goNamed, y MainScreen lee el flag en initState.
    setProfileCompletedSnackBarPending();

    if (_hasSelectedImage && _selectedFile != null) {
      setState(() => _isLoading = true);
      try {
        final photoUrl = await context
            .read<AuthRepository>()
            .uploadProfilePhoto(_selectedFile!);
        await context.read<OnboardingCubit>().completeOnboarding(
              fields: {'photoUrl': photoUrl},
            );
        if (!mounted) return;
        setState(() => _isLoading = false);
      } catch (e) {
        debugPrint('Error subiendo foto: $e');
        if (mounted) {
          setState(() => _isLoading = false);
          AppAlerts.showError(
            context,
            'No se pudo subir la foto. Intenta de nuevo.',
          );
        }
        consumeProfileCompletedSnackBarPending(); // cancelar snackbar si falló
        return;
      }
    } else {
      await context.read<OnboardingCubit>().completeOnboarding();
      if (!mounted) return;
    }

    if (!mounted) return;
    context.goNamed('home');
  }

  void _handleBack() {
    context.goNamed('onboarding-step5');
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
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
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: _hasSelectedImage
                          ? _buildSelectedPhoto()
                          : _buildPhotoPlaceholder(),
                    ),
                  ),

                  SizedBox(height: size.height * 0.04),

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
                            _selectedFile = null;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _pickImage();
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
                    ).animate(controller: _animationController).fadeIn(duration: 400.ms),
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
                    child: SleekSpinner(
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
        child: _selectedFile != null
            ? Image.file(
                _selectedFile!,
                fit: BoxFit.cover,
              )
            : Image.network(
                _imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SleekSpinner(
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.person, size: 80, color: Colors.white70),
                ),
              ),
      ),
    )
        .animate(controller: _animationController)
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildPhotoPlaceholder() {
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 64,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocar para añadir',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          )
        ],
      ),
    )
        .animate(controller: _animationController)
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            curve: Curves.easeOut);
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
