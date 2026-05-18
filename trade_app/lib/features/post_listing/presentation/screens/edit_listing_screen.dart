import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/domain/entities/listing.dart';
import '../cubit/edit_listing_cubit.dart';
import '../cubit/edit_listing_state.dart';

/// Screen for editing an existing listing.
/// Only title, pricePoints, and description are editable.
class EditListingScreen extends StatelessWidget {
  final Listing listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditListingCubit>(),
      child: _EditListingView(listing: listing),
    );
  }
}

class _EditListingView extends StatefulWidget {
  final Listing listing;

  const _EditListingView({required this.listing});

  @override
  State<_EditListingView> createState() => _EditListingViewState();
}

class _EditListingViewState extends State<_EditListingView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.listing.title);
    _descriptionController = TextEditingController(
      text: widget.listing.description ?? '',
    );
    _pointsController = TextEditingController(
      text: widget.listing.pricePoints?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final pointsText = _pointsController.text.trim();
    final pricePoints = int.tryParse(pointsText) ?? 0;

    context.read<EditListingCubit>().updateListing(
          listingId: widget.listing.id,
          title: _titleController.text.trim(),
          pricePoints: pricePoints,
          description: _descriptionController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditListingCubit, EditListingState>(
      listener: (context, state) {
        if (state is EditListingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing updated successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
        if (state is EditListingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is EditListingSubmitting;

        return Scaffold(
          backgroundColor: AppColors.dashboardBackground,
          appBar: AppBar(
            backgroundColor: AppColors.dashboardBackground,
            surfaceTintColor: AppColors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Edit Listing',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildFieldLabel('Post Title'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'Enter your post title',
                    maxLength: 100,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Price Points
                  _buildFieldLabel('Price Points'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _pointsController,
                    hint: 'Enter price in points',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price points is required';
                      }
                      final points = int.tryParse(value.trim());
                      if (points == null || points <= 0) {
                        return 'Enter a valid price greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Description
                  _buildFieldLabel('Description'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: 'Describe your post in detail',
                    maxLines: 4,
                    maxLength: 250,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSubmitting ? 'Saving...' : 'Save Changes',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textOnDarkPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.dashboardSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dashboardBorder),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textOnDarkPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          counterStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ),
    );
  }
}
