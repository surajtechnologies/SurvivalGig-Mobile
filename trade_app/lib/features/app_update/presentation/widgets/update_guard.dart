import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/update_check_result.dart';
import '../cubit/app_update_cubit.dart';
import '../cubit/app_update_state.dart';
import 'update_dialog.dart';

/// Widget that wraps the app's home screen and checks for updates
class UpdateGuard extends StatefulWidget {
  final Widget child;

  const UpdateGuard({super.key, required this.child});

  @override
  State<UpdateGuard> createState() => _UpdateGuardState();
}

class _UpdateGuardState extends State<UpdateGuard> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppUpdateCubit>().initializeAndCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateCubit, AppUpdateState>(
      listener: (context, state) {
        if (state is AppUpdateLoaded && !_dialogShown) {
          _handleUpdateResult(context, state.result);
        }
      },
      child: widget.child,
    );
  }

  void _handleUpdateResult(BuildContext context, UpdateCheckResult result) {
    if (result.type == UpdateType.none) return;

    if (result.type == UpdateType.optional && result.isSnoozed) return;

    if (!mounted) return;

    _dialogShown = true;

    UpdateDialog.show(
      context: context,
      result: result,
      cubit: context.read<AppUpdateCubit>(),
    );
  }
}
