import 'package:IAEntrenar/features/ai_coach/infrastructure/ai_model_manager.dart';
import 'package:flutter/material.dart';

class AiModelDownloadBanner extends StatelessWidget {
  const AiModelDownloadBanner({
    super.key,
    this.margin = EdgeInsets.zero,
    this.compact = false,
  });

  final EdgeInsetsGeometry margin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AiModelDownloadState>(
      stream: AiModelManager.instance.stateStream,
      initialData: AiModelManager.instance.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? AiModelManager.instance.currentState;
        if (!state.isDownloading) return const SizedBox.shrink();

        final theme = Theme.of(context);
        final progress = state.progress;
        final percentText = progress == null
            ? 'Preparando descarga'
            : '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%';

        return Container(
          margin: margin,
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.downloading_rounded,
                    size: compact ? 18 : 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instalando IA local',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    percentText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  'La descarga es unica para toda la app. Puedes cambiar de pantalla y se reutilizara el mismo proceso.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
