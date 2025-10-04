import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Entrenar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.pushNamed('profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del usuario
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Bienvenido, ${authProvider.userProfile?.displayName}!',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tu plan de entrenamiento personalizado está listo',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sección de entrenamiento
            Text(
              'Tu Entrenamiento',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Rutina de Hoy',
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Plan Semanal',
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.track_changes,
                  title: 'Progreso',
                  onTap: () {},
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.restaurant_menu,
                  title: 'Plan Nutricional',
                  onTap: () => context.pushNamed('recipe-list'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección de métricas
            Text(
              'Tus Métricas',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMetricRow(
                      context,
                      label: 'Peso Actual',
                      value: '${authProvider.userProfile?.weight ?? 0} kg',
                    ),
                    const Divider(),
                    _buildMetricRow(
                      context,
                      label: 'IMC',
                      value:
                          '${authProvider.userProfile?.bmi?.toStringAsFixed(1) ?? 0}',
                    ),
                    const Divider(),
                    _buildMetricRow(
                      context,
                      label: 'Porcentaje de Grasa',
                      value:
                          '${authProvider.userProfile?.bodyFatPercentage?.toStringAsFixed(1) ?? 0}%',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Entrenamiento'),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
