import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/create_listing.dart';
import '../cubit/post_listing_cubit.dart';
import '../cubit/post_listing_state.dart';

/// Post Listing Screen
/// Allows users to create a new listing with images
/// Uses BlocProvider pattern per copilot_instructions.md
class PostListingScreen extends StatelessWidget {
  const PostListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PostListingCubit>(),
      child: const _PostListingView(),
    );
  }
}

class _PostListingView extends StatefulWidget {
  const _PostListingView();

  @override
  State<_PostListingView> createState() => _PostListingViewState();
}

class _PostListingViewState extends State<_PostListingView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _pointsController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final cubit = context.read<PostListingCubit>();
    final formState = cubit.state;

    if (formState is PostListingFormState && !formState.canAddMoreImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 photos allowed'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (pickedFile != null) {
        cubit.addImage(pickedFile.path);
      }
    } catch (_) {
      // Error handled silently - no logging outside Dio interceptors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _submitForm() {
    context.read<PostListingCubit>().submitListing();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PostListingCubit, PostListingState>(
      listener: (context, state) {
        if (state is PostListingFormState &&
            _locationController.text != state.location) {
          _locationController.value = TextEditingValue(
            text: state.location,
            selection: TextSelection.collapsed(offset: state.location.length),
          );
        }

        if (state is PostListingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }

        if (state is PostListingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }

        if (state is PostListingFormState && state.imageError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.imageError!),
              backgroundColor: AppColors.error,
            ),
          );
          context.read<PostListingCubit>().clearImageError();
        }

        if (state is PostListingFormState && state.validationError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.validationError!),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is PostListingSubmitting;

        PostListingFormState formState;
        if (state is PostListingFormState) {
          formState = state;
        } else if (state is PostListingSubmitting) {
          formState = state.formData;
        } else if (state is PostListingError) {
          formState = state.formData;
        } else {
          formState = const PostListingFormState();
        }

        return Scaffold(
          backgroundColor: AppColors.dashboardBackground,
          appBar: AppBar(
            backgroundColor: AppColors.dashboardBackground,
            surfaceTintColor: AppColors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'New Post',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textOnDarkPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: const SizedBox(),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textOnDarkPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. I am - Dropdown (Offering/Needing)
                      _buildListingTypeDropdown(formState),
                      const SizedBox(height: 20),

                      // 2. Post Title
                      _buildTextField(
                        controller: _titleController,
                        label: 'Post Title',
                        hint: 'Enter your post title',
                        onChanged: (value) {
                          context.read<PostListingCubit>().updateTitle(value);
                        },
                        maxLength: 100,
                      ),
                      const SizedBox(height: 20),

                      // 3. Photos Section
                      _buildPhotosSection(formState),
                      const SizedBox(height: 20),

                      // 4. Category Dropdown
                      _buildCategoryDropdown(formState),
                      const SizedBox(height: 20),

                      // 5. What You Need in Exchange
                      _buildExchangeSection(formState),
                      const SizedBox(height: 20),

                      // 6. Location
                      _buildLocationField(formState),
                      const SizedBox(height: 20),

                      // 7. Description
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe your post in detail',
                        onChanged: (value) {
                          context.read<PostListingCubit>().updateDescription(
                            value,
                          );
                        },
                        maxLines: 4,
                        maxLength: 250,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '(${formState.description.length}/250)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textOnDarkSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Urgency Level
                      _buildUrgencyDropdown(formState),
                      const SizedBox(height: 20),

                      // Expiry Date
                      _buildExpiryDatePicker(formState),
                      const SizedBox(height: 20),

                      // Current Location
                      _buildCurrentLocationButton(formState),
                      const SizedBox(height: 32),

                      // Post Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (isSubmitting || !formState.isFormValid)
                              ? null
                              : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: formState.isFormValid
                                ? AppColors.primary
                                : AppColors.dashboardSurfaceElevated,
                            foregroundColor: formState.isFormValid
                                ? AppColors.black
                                : AppColors.textOnDarkSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isSubmitting ? 'Posting...' : 'Post',
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
            ],
          ),
        );
      },
    );
  }

  /// Build "I am" dropdown (Offering/Needing)
  Widget _buildListingTypeDropdown(PostListingFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<ListingType>(
            initialValue: formState.listingType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.dashboardSurfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textOnDarkSecondary,
            ),
            items: ListingType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.displayName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textOnDarkPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<PostListingCubit>().updateListingType(value);
              }
            },
          ),
        ),
      ],
    );
  }

  /// Build Photos Section with image picker
  Widget _buildPhotosSection(PostListingFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Display uploaded images
              ...formState.localImagePaths.asMap().entries.map((entry) {
                final index = entry.key;
                final localPath = entry.value;
                final isUploading =
                    formState.isUploadingImage &&
                    formState.uploadingImageIndex == index;
                final isUploaded = index < formState.uploadedImageUrls.length;

                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(localPath),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Upload indicator
                      if (isUploading)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),

                      // Remove button (only show if uploaded)
                      if (isUploaded && !isUploading)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              context.read<PostListingCubit>().removeImage(
                                index,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.dashboardSurfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // Add photo button
              if (formState.canAddMoreImages)
                GestureDetector(
                  onTap: formState.isUploadingImage ? null : _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primary.withValues(alpha: 0.05),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          size: 28,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'These photos will appear in the post. You can add a maximum of 3 photos per post.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textOnDarkSecondary,
          ),
        ),
      ],
    );
  }

  /// Build Category Dropdown
  Widget _buildCategoryDropdown(PostListingFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: formState.isLoadingCategories
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  initialValue: formState.categoryId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.dashboardSurfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    hintText: 'Select a category',
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.textOnDarkSecondary,
                  ),
                  items: formState.categories.map((Category category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(
                        category.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textOnDarkPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    context.read<PostListingCubit>().updateCategory(value);
                  },
                ),
        ),
        if (formState.categoriesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text(
                  formState.categoriesError!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<PostListingCubit>().loadCategories();
                  },
                  child: Text(
                    'Retry',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build Exchange Section (Points/Service)
  Widget _buildExchangeSection(PostListingFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formState.listingType.isOffering
              ? 'What You Need in Exchange'
              : 'What can I offer in Exchange',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<PriceMode>(
            initialValue: formState.priceMode,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.dashboardSurfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textOnDarkSecondary,
            ),
            items: PriceMode.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.displayName,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textOnDarkPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<PostListingCubit>().updatePriceMode(value);
              }
            },
          ),
        ),

        // Show points input when Points is selected
        if (formState.priceMode == PriceMode.points ||
            formState.priceMode == PriceMode.both) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.dashboardSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.dashboardSurfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintText: '100 pts',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
                suffixText: 'pts',
                suffixStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              onChanged: (value) {
                context.read<PostListingCubit>().updatePricePoints(value);
              },
            ),
          ),
        ],

        // Show exchange description input when Skill is selected
        if (formState.priceMode == PriceMode.skill ||
            formState.priceMode == PriceMode.both) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.dashboardSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              initialValue: formState.barterWanted,
              keyboardType: TextInputType.text,
              maxLines: 2,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.dashboardSurfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintText: 'What do you want in exchange?',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              onChanged: (value) {
                context.read<PostListingCubit>().updateBarterWanted(value);
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Build Zipcode field with resolved city label
  Widget _buildLocationField(PostListingFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _locationController,
          label: 'Zipcode',
          hint: 'Enter zipcode',
          keyboardType: TextInputType.number,
          maxLength: 9,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            context.read<PostListingCubit>().updateLocation(value);
          },
        ),
        if (formState.isResolvingLocationCity)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Fetching city...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          )
        else if (formState.locationCity != null &&
            formState.locationCity!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'City: ${formState.locationCity!}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (RegExp(r'^\d{5,9}$').hasMatch(formState.location.trim()) &&
            formState.locationCityError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              formState.locationCityError!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  /// Build Text Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            maxLengthEnforcement: maxLength == null
                ? null
                : MaxLengthEnforcement.enforced,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.dashboardSurfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: hint,
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textOnDarkSecondary,
              ),
              counterText: '',
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Urgency level dropdown (LOW / MEDIUM / HIGH / CRITICAL)
  Widget _buildUrgencyDropdown(PostListingFormState formState) {
    const levels = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urgency Level (optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: formState.urgencyLevel,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.dashboardSurfaceElevated,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          hint: const Text('Select urgency'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('None')),
            ...levels.map(
              (l) => DropdownMenuItem<String>(value: l, child: Text(l)),
            ),
          ],
          onChanged: (v) =>
              context.read<PostListingCubit>().updateUrgencyLevel(v),
        ),
      ],
    );
  }

  /// Expiry date picker
  Widget _buildExpiryDatePicker(PostListingFormState formState) {
    final label = formState.expiresAt == null
        ? 'Select expiry date (optional)'
        : 'Expires: ${formState.expiresAt!.toLocal().toString().split(' ').first}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiry Date (optional)',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  formState.expiresAt ??
                  DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              if (!mounted) return;
              context.read<PostListingCubit>().updateExpiresAt(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dashboardSurfaceElevated),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: formState.expiresAt == null
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textOnDarkPrimary,
                    ),
                  ),
                ),
                if (formState.expiresAt != null)
                  GestureDetector(
                    onTap: () =>
                        context.read<PostListingCubit>().updateExpiresAt(null),
                    child: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Use current GPS location button
  Widget _buildCurrentLocationButton(PostListingFormState formState) {
    final hasLocation =
        formState.latitude != null && formState.longitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Location',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: formState.isDetectingLocation
                ? null
                : () =>
                      context.read<PostListingCubit>().detectCurrentLocation(),
            icon: formState.isDetectingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    hasLocation ? Icons.location_on : Icons.my_location,
                    size: 18,
                    color: hasLocation ? AppColors.primary : null,
                  ),
            label: Text(
              formState.isDetectingLocation
                  ? 'Detecting...'
                  : hasLocation
                  ? 'Current location detected'
                  : 'Use Current Location',
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: hasLocation
                    ? AppColors.primary
                    : AppColors.dashboardSurfaceElevated,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
