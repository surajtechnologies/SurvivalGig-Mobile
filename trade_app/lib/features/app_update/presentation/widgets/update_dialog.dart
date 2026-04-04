import 'package:flutter/material.dart';
import '../../domain/entities/update_check_result.dart';
import '../cubit/app_update_cubit.dart';

/// Dialog widget for displaying update prompts
class UpdateDialog extends StatelessWidget {
  final UpdateCheckResult result;
  final AppUpdateCubit cubit;

  const UpdateDialog({
    super.key,
    required this.result,
    required this.cubit,
  });

  /// Show the update dialog
  static Future<void> show({
    required BuildContext context,
    required UpdateCheckResult result,
    required AppUpdateCubit cubit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: result.type != UpdateType.forced,
      builder: (_) => UpdateDialog(result: result, cubit: cubit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: result.type != UpdateType.forced,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          result.type == UpdateType.forced
              ? Icons.system_update
              : Icons.update,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          result.type == UpdateType.forced
              ? 'Update Required'
              : 'Update Available',
          style: theme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.updateMessage,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Current version: ${result.currentVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Latest version: ${result.latestVersion}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: _buildActions(context),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (result.type == UpdateType.optional) {
      actions.add(
        TextButton(
          onPressed: () {
            cubit.snoozeUpdate();
            Navigator.pop(context);
          },
          child: const Text('Remind Me Later'),
        ),
      );
    }

    actions.add(
      FilledButton(
        onPressed: () {
          cubit.openStore();
        },
        child: const Text('Update Now'),
      ),
    );

    return actions;
  }
}
