import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final user = auth.userProfile;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.goNamed('home'),
        ),
        title: const Text('Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await auth.signOut();
              context.goNamed('login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {},
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.camera_alt,
                        size: 16, color: Colors.white),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text('Toca para actualizar la foto de perfil'),
            const SizedBox(height: 24),
            _sectionCard(
              context,
              title: 'Información Personal',
              items: [
                _infoTile('Nombre', user?.displayName ?? ''),
                _infoTile('Email', user?.email ?? ''),
                _infoTile('Edad', user?.age?.toString() ?? ''),
                _infoTile('Género', user?.gender ?? 'No especificado'),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'Información Física',
              items: [
                _infoTile('Peso (kg)', user?.weight?.toString() ?? ''),
                _infoTile('Altura (cm)', user?.height?.toString() ?? ''),
                _infoTile('Porcentaje de grasa',
                    user?.bodyFatPercentage?.toString() ?? ''),
                _infoTile('IMC', user?.bmi?.toString() ?? ''),
                _infoTile(
                    'Lesiones',
                    user?.injuries.isEmpty ?? true
                        ? 'Ninguna'
                        : user!.injuries.join(', ')),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'Objetivos y Nivel',
              items: [
                _infoTile('Nivel de entrenamiento',
                    user?.trainingLevel ?? 'No especificado'),
                _infoTile(
                    'Objetivos',
                    user?.goals.isEmpty ?? true
                        ? 'No especificados'
                        : user!.goals.join(', ')),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              context,
              title: 'Información de la Cuenta',
              items: [
                _infoTile(
                    'Plan Premium', user?.isPremium ?? false ? 'Sí' : 'No'),
                _infoTile('Plan Generado',
                    user?.planGenerated ?? false ? 'Sí' : 'No'),
                _infoTile(
                    'Versión del Modelo IA', user?.aiModelVersion ?? 'v1.3'),
                _infoTile('Último inicio de sesión',
                    user?.lastLogin?.toString() ?? 'No disponible'),
                _infoTile('Cuenta creada',
                    user?.createdAt?.toString() ?? 'No disponible'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> items,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              )),
          const SizedBox(height: 16),
          if (child != null) child else ...items,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          readOnly: true,
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.edit, size: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white10,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
