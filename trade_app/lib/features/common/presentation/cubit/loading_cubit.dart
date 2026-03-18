import 'package:flutter_bloc/flutter_bloc.dart';

/// Global loading state
/// Used to show/hide loading overlay across the app
class LoadingState {
  final bool isLoading;
  final String? message;

  const LoadingState({this.isLoading = false, this.message});

  LoadingState copyWith({bool? isLoading, String? message}) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
    );
  }
}

/// Global loading cubit
/// Manages loading state for API calls throughout the app
class LoadingCubit extends Cubit<LoadingState> {
  LoadingCubit() : super(const LoadingState());

  /// Show loading overlay
  void showLoading({String? message}) {
    emit(LoadingState(isLoading: true, message: message));
  }

  /// Hide loading overlay
  void hideLoading() {
    emit(const LoadingState(isLoading: false));
  }
}
