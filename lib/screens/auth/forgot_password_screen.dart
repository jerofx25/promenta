import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  late final AnimationController _animationController;

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
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(
        _emailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _isSuccess = success;
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error al enviar el correo de restablecimiento. Intu00e9ntalo de nuevo.')),
        );
      }
    }
  }

  void _navigateBack() => context.goNamed('login');

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button

                  SizedBox(height: size.height * 0.05),

                  // Header text
                  Text(
                    'Olvidaste tu contraseña?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 12),

                  Text(
                    'Ingresa tu correo electronico y te enviaremos un enlace para restablecer tu contraseña',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 100.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: size.height * 0.06),

                  if (!_isSuccess) ...[
                    // Fixed bracket syntax
                    // Email form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            hintText: 'Ingresa tu email',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, ingresa tu email';
                              }
                              if (!value.contains('@')) {
                                return 'Por favor, ingresa un email valido';
                              }
                              return null;
                            },
                          )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 500.ms, delay: 200.ms)
                              .slideY(begin: 0.3, end: 0),

                          SizedBox(height: size.height * 0.04),

                          // Reset button
                          CustomButton(
                            text: 'Enviar enlace de restablecimiento',
                            onPressed: _handleResetPassword,
                            isLoading: _isLoading,
                            width: double.infinity,
                          )
                              .animate(controller: _animationController)
                              .fadeIn(duration: 500.ms, delay: 300.ms)
                              .slideY(begin: 0.3, end: 0),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Fixed bracket syntax
                    // Success message
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Enlace enviado!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hemos enviado un enlace de restablecimiento a ${_emailController.text}. Por favor, revisa tu correo electronico.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.0, 1.0)),
                  ],

                  SizedBox(height: size.height * 0.04),

                  // Return to login button
                  Center(
                    child: TextButton.icon(
                      onPressed: _navigateBack,
                      icon: Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        'Volver a inicio de sesion',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
