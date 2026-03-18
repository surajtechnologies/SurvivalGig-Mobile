import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

typedef PincodeSubmit = Future<String?> Function(String pincode);

/// Dialog for collecting pincode and updating current city.
class LocationUpdateDialog extends StatefulWidget {
  final bool isMandatory;
  final PincodeSubmit onSubmit;

  const LocationUpdateDialog({
    super.key,
    required this.isMandatory,
    required this.onSubmit,
  });

  @override
  State<LocationUpdateDialog> createState() => _LocationUpdateDialogState();
}

class _LocationUpdateDialogState extends State<LocationUpdateDialog> {
  final TextEditingController _pincodeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pincode = _pincodeController.text.trim();

    if (!RegExp(r'^\d{5,9}$').hasMatch(pincode)) {
      setState(() {
        _errorText = 'Please enter a valid 5 to 9-digit US pincode';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSubmitting = true;
    });

    final errorMessage = await widget.onSubmit(pincode);

    if (!mounted) return;

    if (errorMessage != null) {
      setState(() {
        _isSubmitting = false;
        _errorText = errorMessage;
      });
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isMandatory,
      child: AlertDialog(
        title: Text(
          'Update Location',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your pincode to fetch your city',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMd),
            TextField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ],
              onSubmitted: (_) => _isSubmitting ? null : _submit(),
              decoration: InputDecoration(
                hintText: 'Enter zipcode (5-9 digits)',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMd,
                  vertical: AppDimensions.spacingSm,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  borderSide: const BorderSide(color: AppColors.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: AppDimensions.spacingSm),
              Text(
                _errorText!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
        actions: [
          if (!widget.isMandatory)
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: AppDimensions.iconSizeSm,
                    width: AppDimensions.iconSizeSm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textPrimary,
                      ),
                    ),
                  )
                : Text(
                    'Update',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
