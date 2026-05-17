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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (state.isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.dashboardSurface
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isDark
                            ? AppColors.dashboardBorder
                            : AppColors.dividerColor,
                      ),
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
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textOnDarkPrimary
                                  : AppColors.textPrimary,
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
