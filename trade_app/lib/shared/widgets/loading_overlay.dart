import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../features/common/presentation/cubit/loading_cubit.dart';

/// Global loading overlay widget
/// Wraps the entire app to show loading indicator during API calls
class LoadingOverlay extends StatelessWidget {
  final Widget child;

  const LoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoadingCubit, LoadingState>(
      builder: (context, state) {
        return Stack(
          children: [
            child,
            if (state.isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        if (state.message != null) ...[
                          const SizedBox(height: 16.0),
                          Text(
                            state.message!,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
