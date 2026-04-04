import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/check_for_update_usecase.dart';
import '../../domain/usecases/initialize_update_usecase.dart';
import '../../domain/usecases/open_store_usecase.dart';
import '../../domain/usecases/perform_native_update_usecase.dart';
import '../../domain/usecases/snooze_update_usecase.dart';
import 'app_update_state.dart';

/// Cubit for managing app update state
class AppUpdateCubit extends Cubit<AppUpdateState> {
  final InitializeUpdateUseCase initializeUpdateUseCase;
  final CheckForUpdateUseCase checkForUpdateUseCase;
  final OpenStoreUseCase openStoreUseCase;
  final SnoozeUpdateUseCase snoozeUpdateUseCase;
  final PerformNativeUpdateUseCase performNativeUpdateUseCase;

  AppUpdateCubit({
    required this.initializeUpdateUseCase,
    required this.checkForUpdateUseCase,
    required this.openStoreUseCase,
    required this.snoozeUpdateUseCase,
    required this.performNativeUpdateUseCase,
  }) : super(const AppUpdateInitial());

  /// Initialize remote config and check for updates
  Future<void> initializeAndCheck() async {
    emit(const AppUpdateLoading());

    final initResult = await initializeUpdateUseCase();

    await initResult.fold(
      (failure) async {
        emit(AppUpdateError(message: failure.message, code: failure.code));
      },
      (_) async {
        await checkForUpdate();
      },
    );
  }

  /// Check for available updates
  Future<void> checkForUpdate() async {
    final result = await checkForUpdateUseCase();

    result.fold(
      (failure) {
        emit(AppUpdateError(message: failure.message, code: failure.code));
      },
      (updateResult) {
        emit(AppUpdateLoaded(result: updateResult));
      },
    );
  }

  /// Open the platform store URL
  Future<void> openStore() async {
    final result = await openStoreUseCase();

    result.fold(
      (failure) {
        emit(AppUpdateError(message: failure.message, code: failure.code));
      },
      (_) {},
    );
  }

  /// Snooze the optional update
  Future<void> snoozeUpdate() async {
    final result = await snoozeUpdateUseCase();

    result.fold(
      (failure) {
        emit(AppUpdateError(message: failure.message, code: failure.code));
      },
      (_) {
        emit(const AppUpdateSnoozed());
      },
    );
  }

  /// Perform Android native in-app update
  Future<void> performNativeUpdate() async {
    final result = await performNativeUpdateUseCase();

    result.fold(
      (failure) {
        // Silently ignore native update failures
      },
      (_) {},
    );
  }
}
