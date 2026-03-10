import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/core/ui/buttons.dart';
import 'package:IAEntrenar/core/ui/inputs.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: const LoginScreenContent(),
    );
  }
}

class LoginScreenContent extends StatefulWidget {
  const LoginScreenContent({super.key});

  @override
  State<LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<LoginScreenContent> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
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
      context.read<AuthBloc>().add(
            AuthSignInRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
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

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        setState(() {
          _isLoading = state.status == AuthFlowStatus.loading;
        });

        if (state.status == AuthFlowStatus.failure && mounted) {
          final message =
              state.error ?? 'Error al iniciar sesión. Inténtalo de nuevo.';
          AppAlerts.showError(context, message);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.06),
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
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
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
      ),
    );
  }
}
