import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/submit_report_usecase.dart';
import 'submit_report_state.dart';

/// Submit report cubit
class SubmitReportCubit extends Cubit<SubmitReportState> {
  final SubmitReportUseCase submitReportUseCase;

  SubmitReportCubit({required this.submitReportUseCase})
    : super(const SubmitReportInitial());

  /// Submit listing report
  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String reason,
    required String description,
  }) async {
    emit(const SubmitReportSubmitting());

    final result = await submitReportUseCase(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      description: description,
    );

    result.fold(
      (failure) =>
          emit(SubmitReportError(message: failure.message, code: failure.code)),
      (message) => emit(SubmitReportSuccess(message: message)),
    );
  }

  /// Reset to initial state
  void reset() {
    emit(const SubmitReportInitial());
  }
}
