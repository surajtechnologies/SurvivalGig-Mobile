/// Submit report states
abstract class SubmitReportState {
  const SubmitReportState();
}

/// Initial state
class SubmitReportInitial extends SubmitReportState {
  const SubmitReportInitial();
}

/// Submitting state
class SubmitReportSubmitting extends SubmitReportState {
  const SubmitReportSubmitting();
}

/// Success state
class SubmitReportSuccess extends SubmitReportState {
  final String message;

  const SubmitReportSuccess({this.message = 'Report submitted successfully'});
}

/// Error state
class SubmitReportError extends SubmitReportState {
  final String message;
  final String? code;

  const SubmitReportError({required this.message, this.code});
}
