import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/social_button.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // Start animation after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Credenciales inválidas. Inténtalo de nuevo.')),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();

    setState(() {
      _isGoogleLoading = false;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Error al iniciar sesión con Google. Inténtalo de nuevo.')),
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() {
      _isAppleLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();

    setState(() {
      _isAppleLoading = false;
    });

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Error al iniciar sesión con Apple. Inténtalo de nuevo.')),
      );
    }
  }

  void _navigateToSignUp() {
    context.pushNamed('signup');
  }

  void _navigateToForgotPassword() {
    context.pushNamed('forgot-password');
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
              "https://pixabay.com/get/g1668d9395e4ed7ca8190288f607d6e0db08021276cca174fb9c4a5151c3874c5d41b19c2934d8883ba5aa5097ab3ec01d56db18666abe6e1d4f40def57f3606e_1280.jpg",
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
                  SizedBox(height: size.height * 0.06),

                  // App Logo/Branding
                  Center(
                    child: Hero(
                      tag: 'appLogo',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: theme.colorScheme.onPrimary,
                          size: 40,
                        ),
                      )
                          .animate(controller: _animationController)
                          .scale(duration: 700.ms, curve: Curves.elasticOut),
                    ),
                  ),

                  SizedBox(height: size.height * 0.03),

                  // Welcome text
                  Text(
                    '¡Bienvenido!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 300.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Inicia sesión para continuar',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  SizedBox(height: size.height * 0.05),

                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingresa tu email';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor, ingresa un email válido';
                            }
                            return null;
                          },
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms, delay: 500.ms)
                            .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 20),

                        CustomTextField(
                          label: 'Contraseña',
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          onSuffixIconPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms, delay: 600.ms)
                            .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 12),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _navigateToForgotPassword,
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms, delay: 700.ms)
                            .slideX(begin: 0.3, end: 0),

                        SizedBox(height: size.height * 0.02),

                        // Login button
                        CustomButton(
                          text: 'Iniciar Sesión',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                          width: double.infinity,
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms, delay: 800.ms)
                            .slideY(begin: 0.3, end: 0),

                        SizedBox(height: size.height * 0.03),

                        // Divider with text
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'O continúa con',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withOpacity(0.3),
                                thickness: 1,
                              ),
                            ),
                          ],
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms, delay: 900.ms),

                        SizedBox(height: size.height * 0.03),

                        // Social login buttons
                        Row(
                          children: [
                            // Google button
                            Expanded(
                              child: SocialButton(
                                text: 'Google',
                                icon: Icons.g_mobiledata,
                                backgroundColor: Colors.white,
                                textColor: Colors.black87,
                                onPressed: _handleGoogleLogin,
                                isLoading: _isGoogleLoading,
                              )
                                  .animate(controller: _animationController)
                                  .fadeIn(duration: 600.ms, delay: 1000.ms)
                                  .slideY(begin: 0.3, end: 0),
                            ),

                            const SizedBox(width: 16),

                            // Apple button
                            Expanded(
                              child: SocialButton(
                                text: 'Apple',
                                icon: Icons.apple,
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                onPressed: _handleAppleLogin,
                                isLoading: _isAppleLoading,
                              )
                                  .animate(controller: _animationController)
                                  .fadeIn(duration: 600.ms, delay: 1100.ms)
                                  .slideY(begin: 0.3, end: 0),
                            ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.04),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes una cuenta?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            TextButton(
                              onPressed: _navigateToSignUp,
                              child: Text(
                                'Regístrate',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate(controller: _animationController)
                            .fadeIn(duration: 600.ms, delay: 1200.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
