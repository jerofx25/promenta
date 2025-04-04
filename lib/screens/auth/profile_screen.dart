import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil', style: theme.textTheme.titleLarge),
        backgroundColor: color.surface,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            if (authProvider.profileImage != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.primary, width: 3),
                ),
                child: ClipOval(
                  child: Image.network(
                    authProvider.profileImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Name
            Text(
              authProvider.name ?? 'Nombre no definido',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              authProvider.email ?? 'Email no definido',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),

            Divider(color: color.outline.withOpacity(0.3)),
            const SizedBox(height: 16),

            // Age, Height, Weight
            _buildDataTile(
                context, 'Edad', '${authProvider.name ?? '--'} años'),
            _buildDataTile(
                context,
                'Estatura',
                authProvider.height != null
                    ? '${authProvider.height!.toStringAsFixed(0)} ${authProvider.heightUnit}'
                    : '--'),
            _buildDataTile(
                context,
                'Peso',
                authProvider.height != null
                    ? '${authProvider.height!.toStringAsFixed(1)} ${authProvider.heightUnit}'
                    : '--'),

            const SizedBox(height: 16),

            Divider(color: color.outline.withOpacity(0.3)),
            const SizedBox(height: 16),

            // Injuries
            _buildDataTile(
                context,
                'Lesiones',
                (authProvider.injuries?.isEmpty ?? true)
                    ? 'Ninguna'
                    : authProvider.injuries!.join(', ')),

            // Training Frequency & Goal
            _buildDataTile(context, 'Frecuencia de Entrenamiento',
                authProvider.trainingFrequency ?? '--'),
            _buildDataTile(
                context, 'Objetivo', authProvider.fitnessGoal ?? '--'),

            const SizedBox(height: 16),
            Divider(color: color.outline.withOpacity(0.3)),
            const SizedBox(height: 16),

            // Diet
            _buildDataTile(
                context,
                'Hábitos Alimenticios',
                (authProvider.dietaryHabits?.isEmpty ?? true)
                    ? 'Ninguno'
                    : authProvider.dietaryHabits!.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
