import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/core/ui/buttons.dart';
import 'package:IAEntrenar/core/ui/inputs.dart';
import 'package:IAEntrenar/core/ui/alerts.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: const SignupScreenContent(),
    );
  }
}

class SignupScreenContent extends StatefulWidget {
  const SignupScreenContent({super.key});

  @override
  State<SignupScreenContent> createState() => _SignupScreenContentState();
}

class _SignupScreenContentState extends State<SignupScreenContent>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedCountryCode = '+34';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nombre completo';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu número de teléfono';
    }
    final phoneRegex = RegExp(r'^[\d\s-]{7,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Ingresa un número de teléfono válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthRegisterRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _fullNameController.text.trim(),
              phone: '$_selectedCountryCode ${_phoneController.text.trim()}',
            ),
          );
    }
  }

  void _navigateBack() => context.goNamed('login');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        setState(() {
          _isLoading = state.status == AuthFlowStatus.loading;
        });

        if (state.status == AuthFlowStatus.failure && mounted) {
          final message =
              state.error ?? 'Error al crear la cuenta. Inténtalo de nuevo.';
          AppAlerts.showError(context, message);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: _navigateBack,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.only(left: 8),
                      iconSize: 18,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.2, end: 0),
                  const SizedBox(height: 20),
                  Text(
                    'Crear Cuenta',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 30),
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'Nombre Completo',
                    hintText: 'Ingresa tu nombre completo',
                    prefixIcon: Icons.person_outline,
                    validator: _validateFullName,
                    textCapitalization: TextCapitalization.words,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 300.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    hintText: 'Ingresa tu correo electronico',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Teléfono',
                    hintText: 'Ingresa tu numero de telefono',
                    prefixWidget: CountryCodePicker(
                      onChanged: (country) {
                        setState(() {
                          _selectedCountryCode = country.dialCode ?? '+34';
                        });
                      },
                      initialSelection: 'ES',
                      favorite: const ['+34', 'ES', '+1', 'US'],
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      alignLeft: false,
                      padding: EdgeInsets.zero,
                      textStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      dialogTextStyle: theme.textTheme.bodyLarge,
                      dialogBackgroundColor: theme.scaffoldBackgroundColor,
                      searchDecoration: InputDecoration(
                        hintText: 'Buscar país...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 500.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Contraseña',
                    hintText: 'Ingresa tu contraseña',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_isConfirmPasswordVisible,
                    validator: _validateConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 700.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: 'Crear Cuenta',
                    onPressed: _handleSignup, 
                    isLoading: _isLoading,
                    width: double.infinity,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 800.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _navigateBack,
                      child: Text(
                        '¿Ya tienes una cuenta? Inicia sesión',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 300.ms, delay: 900.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
