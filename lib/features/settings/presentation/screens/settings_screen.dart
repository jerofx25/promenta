import 'dart:async';

import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/features/ai_coach/infrastructure/ai_model_manager.dart';
import 'package:IAEntrenar/features/metrics/domain/entities/metric_unit.dart';
import 'package:IAEntrenar/services/apple_health_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefsDefaultWeightUnitKey = 'settings_default_weight_unit_v1';

  bool _healthLoading = false;
  bool? _healthGranted;

  AiModelDownloadState _modelState = AiModelManager.instance.currentState;
  StreamSubscription<AiModelDownloadState>? _modelSub;

  MetricUnit _defaultWeightUnit = MetricUnit.kg;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _modelSub = AiModelManager.instance.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _modelState = state);
    });
    _refreshModelState();
  }

  @override
  void dispose() {
    _modelSub?.cancel();
    _modelSub = null;
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnit = prefs.getString(_prefsDefaultWeightUnitKey);
    final parsed = MetricUnit.fromFirestore(savedUnit);
    if (!mounted) return;
    setState(() {
      if (parsed != null && parsed.isWeight) _defaultWeightUnit = parsed;
    });
  }

  Future<void> _setDefaultWeightUnit(MetricUnit unit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsDefaultWeightUnitKey, unit.firestoreValue);
    if (!mounted) return;
    setState(() => _defaultWeightUnit = unit);
  }

  Future<void> _requestHealthPermissions() async {
    if (!AppleHealthService.isSupported) return;
    setState(() {
      _healthLoading = true;
      _healthGranted = null;
    });
    try {
      final health = AppleHealthService();
      final granted = await health.requestPermissions();
      if (!mounted) return;
      setState(() {
        _healthGranted = granted;
        _healthLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Permisos de Salud concedidos.'
                : 'Permisos denegados. Debes habilitarlos en Salud/Health Connect.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _healthGranted = false;
        _healthLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron solicitar permisos de Salud.'),
        ),
      );
    }
  }

  Future<void> _refreshModelState() async {
    final state = await AiModelManager.instance.refreshState();
    if (!mounted) return;
    setState(() => _modelState = state);
  }

  Future<void> _downloadModel() async {
    AiModelManager.instance.ensureDownloaded();
  }

  Future<void> _resetStressRecoveryBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('baseline_hrv_ms');
    await prefs.remove('baseline_sleep_h');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Baseline de estrés/recuperación reiniciada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<AuthBloc>().state.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Cuenta', theme),
          const SizedBox(height: 8),
          _card(
            theme,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(profile?.displayName ?? 'Perfil'),
                subtitle: Text(profile?.email ?? 'Ver y editar perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed('profile'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  context.read<AuthBloc>().add(const AuthSignOutRequested());
                  context.goNamed('login');
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('Salud', theme),
          const SizedBox(height: 8),
          _card(
            theme,
            children: [
              ListTile(
                leading: Icon(
                  Icons.health_and_safety_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Conectar Salud'),
                subtitle: Text(
                  AppleHealthService.isSupported
                      ? (_healthGranted == null
                          ? 'Permisos para leer pasos, calorías, ejercicio, sueño y HRV.'
                          : _healthGranted == true
                              ? 'Permisos concedidos.'
                              : 'Permisos denegados. Actívalos en Salud/Health Connect.')
                      : 'No disponible en esta plataforma.',
                ),
                trailing: _healthLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _healthGranted == false
                            ? Icons.error_outline
                            : Icons.chevron_right,
                        color: _healthGranted == false
                            ? theme.colorScheme.error
                            : null,
                      ),
                onTap: _healthLoading ? null : _requestHealthPermissions,
              ),
              if (AppleHealthService.isSupported &&
                  _healthGranted == false) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    'Si ya lo denegaste, Android/iOS puede no volver a mostrar el popup. '
                    'Ve a la app Salud/Health Connect y habilita permisos para “Promenta”.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('Reiniciar baseline de Estrés/Recuperación'),
                subtitle: const Text(
                  'Útil si cambiaste de rutina o el score no se ve coherente.',
                ),
                onTap: _resetStressRecoveryBaseline,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('Unidades', theme),
          const SizedBox(height: 8),
          _card(
            theme,
            children: [
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Unidad por defecto para RM'),
                subtitle:
                    Text(_defaultWeightUnit == MetricUnit.kg ? 'kg' : 'lb'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: SegmentedButton<MetricUnit>(
                  segments: const [
                    ButtonSegment(
                      value: MetricUnit.kg,
                      label: Text('kg'),
                      icon: Icon(Icons.straighten, size: 18),
                    ),
                    ButtonSegment(
                      value: MetricUnit.lb,
                      label: Text('lb'),
                      icon: Icon(Icons.monitor_weight_outlined, size: 18),
                    ),
                  ],
                  selected: {_defaultWeightUnit},
                  onSelectionChanged: (s) => _setDefaultWeightUnit(s.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('IA (offline)', theme),
          const SizedBox(height: 8),
          _card(
            theme,
            children: [
              Builder(builder: (context) {
                final isDownloading = _modelState.isDownloading;
                final isDownloaded = _modelState.isDownloaded;
                final progress = _modelState.progress;
                final progressText = progress == null
                    ? 'Preparando descarga'
                    : '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';

                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.auto_awesome),
                      title: const Text('Modelo local'),
                      subtitle: Text(
                        isDownloaded
                            ? 'Descargado'
                            : isDownloading
                                ? 'Descargando IA local: $progressText'
                                : 'No descargado (se descarga una vez)',
                      ),
                    ),
                    if (_modelState.error != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          _modelState.error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isDownloading)
                            LinearProgressIndicator(value: progress)
                          else
                            const SizedBox(height: 6),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isDownloading ? null : _downloadModel,
                              child: Text(isDownloaded
                                  ? 'Revisar / reintentar descarga'
                                  : 'Descargar modelo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('Acerca de', theme),
          const SizedBox(height: 8),
          _card(
            theme,
            children: const [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Promenta'),
                subtitle: Text('Configuración y estado del sistema'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, ThemeData theme) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _card(ThemeData theme, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(children: children),
    );
  }
}
