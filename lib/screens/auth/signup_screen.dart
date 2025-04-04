import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/social_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        context.goNamed('onboarding-step0');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al crear la cuenta. Inténtalo de nuevo.')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isGoogleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    setState(() => _isGoogleLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrarse con Google.')),
      );
    }
  }

  Future<void> _handleAppleSignup() async {
    setState(() => _isAppleLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();
    setState(() => _isAppleLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrarse con Apple.')),
      );
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
          Positioned.fill(
            child: Image.network(
              "https://pixabay.com/get/gdd83f5d08de8479ea881b6c23d79d6322c9f907c2a5dd8c33c5e59ff0184e0c1b8ea85a08bfa06dc6c74130ee1828be0e89584305905b960c2ec8a651f5a1cc7_1280.jpg",
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: _navigateBack,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),

                  // Formulario...
                  // ❗ Resto del cuerpo permanece igual

                  CustomButton(
                    text: 'Crear Cuenta',
                    onPressed: _handleSignup,
                    isLoading: _isLoading,
                    width: double.infinity,
                  )
                      .animate(controller: _animationController)
                      .fadeIn(duration: 500.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
