import 'package:equatable/equatable.dart';
import '../../domain/entities/update_check_result.dart';

/// App update state
abstract class AppUpdateState extends Equatable {
  const AppUpdateState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any update check
class AppUpdateInitial extends AppUpdateState {
  const AppUpdateInitial();
}

/// Loading state while checking for updates
class AppUpdateLoading extends AppUpdateState {
  const AppUpdateLoading();
}

/// Update check completed successfully
class AppUpdateLoaded extends AppUpdateState {
  final UpdateCheckResult result;

  const AppUpdateLoaded({required this.result});

  @override
  List<Object?> get props => [result.type, result.currentVersion, result.latestVersion, result.isSnoozed];
}

/// Update snoozed successfully
class AppUpdateSnoozed extends AppUpdateState {
  const AppUpdateSnoozed();
}

/// Update check failed
class AppUpdateError extends AppUpdateState {
  final String message;
  final String? code;

  const AppUpdateError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}
