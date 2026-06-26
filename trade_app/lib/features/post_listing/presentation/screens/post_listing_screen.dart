import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/create_listing.dart';
import '../cubit/post_listing_cubit.dart';
import '../cubit/post_listing_state.dart';
import 'listing_location_picker_screen.dart';

class PostListingResult {
  final bool didCreate;
  final double? latitude;
  final double? longitude;

  const PostListingResult({
    required this.didCreate,
    this.latitude,
    this.longitude,
  });
}

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
  final _scrollController = ScrollController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _descriptionFocusNode.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
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
        if (state is PostListingSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(
            PostListingResult(
              didCreate: true,
              latitude: state.formData.latitude,
              longitude: state.formData.longitude,
            ),
          );
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
          resizeToAvoidBottomInset: true,
          appBar: AppBar(
            backgroundColor: AppColors.dashboardBackground,
            surfaceTintColor: AppColors.transparent,
            elevation: 0,
            toolbarHeight: 52,
            centerTitle: true,
            title: Text(
              'New Post',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textOnDarkPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: const SizedBox(),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textOnDarkPrimary,
                  size: 22,
                ),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. I am - Dropdown (Offering/Needing)
                      _buildListingTypeDropdown(formState),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // 3. Photos Section
                      _buildPhotosSection(formState),
                      const SizedBox(height: 16),

                      // 4. Category Dropdown
                      _buildCategoryDropdown(formState),
                      const SizedBox(height: 16),

                      // 5. What You Need in Exchange
                      _buildExchangeSection(formState),
                      const SizedBox(height: 16),

                      // 6. Listing Location
                      _buildListingLocationSection(formState),
                      const SizedBox(height: 16),

                      // 7. Description
                      _buildTextField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocusNode,
                        label: 'Description',
                        hint: 'Describe your post in detail',
                        onChanged: (value) {
                          context.read<PostListingCubit>().updateDescription(
                            value,
                          );
                        },
                        // Keep the whole multi-line field above the keyboard by
                        // reserving space below the caret when it scrolls into
                        // view. Fixed (not keyboard-inset based) to avoid jitter.
                        scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 220),
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
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Urgency Level
                      _buildUrgencyDropdown(formState),
                      const SizedBox(height: 16),

                      // Expiry Date
                      _buildExpiryDatePicker(formState),
                      const SizedBox(height: 16),

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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isSubmitting ? 'Posting...' : 'Post',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
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
                horizontal: 14,
                vertical: 12,
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 14,
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
                  width: 88,
                  height: 88,
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(localPath),
                          width: 88,
                          height: 88,
                          cacheWidth: 200,
                          cacheHeight: 200,
                          filterQuality: FilterQuality.low,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Upload indicator
                      if (isUploading)
                        Container(
                          width: 88,
                          height: 88,
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
                    width: 88,
                    height: 88,
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
                          size: 24,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            fontSize: 11,
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
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// Build Category Dropdown
  Widget _buildCategoryDropdown(PostListingFormState formState) {
    final categories = _flattenCategories(formState.categories);
    final selectedCategory = _categoryById(categories, formState.categoryId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
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
              : InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: categories.isEmpty
                      ? null
                      : () => _showCategoryPicker(
                          categories: categories,
                          selectedCategoryId: formState.categoryId,
                        ),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.dashboardSurfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedCategory?.name ?? 'Select a category',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: selectedCategory == null
                                  ? AppColors.textOnDarkSecondary
                                  : AppColors.textOnDarkPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ],
                    ),
                  ),
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

  List<_CategoryPickerItem> _flattenCategories(List<Category> categories) {
    final items = <_CategoryPickerItem>[];

    void addCategory(Category category, int depth) {
      if (!category.isActive) return;
      items.add(_CategoryPickerItem(category: category, depth: depth));

      for (final child in category.children ?? const <Category>[]) {
        addCategory(child, depth + 1);
      }
    }

    for (final category in categories) {
      addCategory(category, 0);
    }

    return items;
  }

  Category? _categoryById(List<_CategoryPickerItem> categories, String? id) {
    if (id == null || id.isEmpty) return null;

    for (final item in categories) {
      if (item.category.id == id) {
        return item.category;
      }
    }

    return null;
  }

  Future<void> _showCategoryPicker({
    required List<_CategoryPickerItem> categories,
    required String? selectedCategoryId,
  }) async {
    final selectedCategory = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.dashboardSurface,
      barrierColor: AppColors.dashboardOverlay,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 10, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Category',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textOnDarkPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.dashboardBorder),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: AppColors.dashboardBorder,
                    ),
                    itemBuilder: (context, index) {
                      final item = categories[index];
                      final category = item.category;
                      final isSelected = category.id == selectedCategoryId;

                      return ListTile(
                        contentPadding: EdgeInsets.only(
                          left: 18 + (item.depth * 16),
                          right: 14,
                        ),
                        dense: true,
                        title: Text(
                          category.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textOnDarkPrimary,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.pop(sheetContext, category.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selectedCategory == null) return;
    context.read<PostListingCubit>().updateCategory(selectedCategory);
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
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
                horizontal: 14,
                vertical: 12,
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
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 14,
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
          const SizedBox(height: 10),
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
                  horizontal: 14,
                  vertical: 12,
                ),
                hintText: '100 pts',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 14,
                ),
                suffixText: 'pts',
                suffixStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 13,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkPrimary,
                fontSize: 14,
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
          const SizedBox(height: 10),
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
                  horizontal: 14,
                  vertical: 12,
                ),
                hintText: 'What do you want in exchange?',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 14,
                ),
              ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkPrimary,
                fontSize: 14,
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

  Widget _buildListingLocationSection(PostListingFormState formState) {
    final hasLocation =
        formState.latitude != null && formState.longitude != null;
    final locationTitle = formState.locationCity?.trim().isNotEmpty == true
        ? formState.locationCity!.trim()
        : hasLocation
        ? 'Selected location'
        : 'No location selected';
    final coordinateLabel = hasLocation
        ? '${formState.latitude!.toStringAsFixed(6)}, ${formState.longitude!.toStringAsFixed(6)}'
        : 'Choose a map pin or use your device location';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Listing Location',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasLocation
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.dashboardSurfaceElevated,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on : Icons.location_searching,
                color: hasLocation
                    ? AppColors.primary
                    : AppColors.textOnDarkSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      coordinateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildLocationAction(
                icon: Icons.map_rounded,
                label: 'Select from Map',
                onPressed: formState.isDetectingLocation
                    ? null
                    : () => _openMapLocationPicker(formState),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildLocationAction(
                icon: Icons.my_location_rounded,
                label: formState.isDetectingLocation
                    ? 'Detecting...'
                    : 'Use Current Location',
                isLoading: formState.isDetectingLocation,
                onPressed: formState.isDetectingLocation
                    ? null
                    : () => _useCurrentLocation(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(icon, size: 16),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textOnDarkSecondary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _openMapLocationPicker(PostListingFormState formState) async {
    final initialTarget = await _resolveMapInitialTarget(formState);
    if (!mounted) return;

    final selected = await Navigator.push<PickedListingLocation>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListingLocationPickerScreen(initialTarget: initialTarget),
      ),
    );

    if (selected == null || !mounted) return;
    context.read<PostListingCubit>().updateSelectedMapLocation(
      latitude: selected.latitude,
      longitude: selected.longitude,
    );
  }

  Future<LatLng> _resolveMapInitialTarget(
    PostListingFormState formState,
  ) async {
    if (formState.latitude != null && formState.longitude != null) {
      return LatLng(formState.latitude!, formState.longitude!);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return defaultListingLocation;

      final permission = await Geolocator.checkPermission();
      final hasPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!hasPermission) return defaultListingLocation;

      final lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (_isRecentEnough(lastKnownPosition)) {
        return LatLng(lastKnownPosition!.latitude, lastKnownPosition.longitude);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return defaultListingLocation;
    }
  }

  bool _isRecentEnough(Position? position) {
    final timestamp = position?.timestamp;
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp).inMinutes <= 10;
  }

  Future<void> _useCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      await _showLocationSettingsAlert(openLocationSettings: true);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await _showLocationSettingsAlert(openLocationSettings: false);
      return;
    }

    context.read<PostListingCubit>().detectCurrentLocation();
  }

  Future<void> _showLocationSettingsAlert({
    required bool openLocationSettings,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dashboardSurface,
          title: Text(
            'Location Permission',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textOnDarkPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            openLocationSettings
                ? 'Location services are disabled. Please update it in Settings.'
                : 'Location permission not given. Please update it in Settings.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnDarkSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (openLocationSettings) {
                  await Geolocator.openLocationSettings();
                } else {
                  await Geolocator.openAppSettings();
                }
              },
              child: Text(
                'Open Settings',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build Text Field
  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onTap,
    EdgeInsets? scrollPadding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textOnDarkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.dashboardSurfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            maxLength: maxLength,
            maxLengthEnforcement: maxLength == null
                ? null
                : MaxLengthEnforcement.enforced,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            scrollPadding:
                scrollPadding ?? const EdgeInsets.fromLTRB(20, 20, 20, 80),
            onTap: onTap,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.dashboardSurfaceElevated,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14,
              ),
              counterText: '',
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkPrimary,
              fontSize: 14,
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
          'Urgency Level',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
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
              vertical: 12,
            ),
          ),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontSize: 14,
          ),
          hint: Text(
            'Select urgency',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnDarkSecondary,
              fontSize: 14,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'None',
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
              ),
            ),
            ...levels.map(
              (l) => DropdownMenuItem<String>(
                value: l,
                child: Text(
                  l,
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                ),
              ),
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
        ? 'Select expiry date'
        : 'Expires: ${formState.expiresAt!.toLocal().toString().split(' ').first}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expiry Date',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textOnDarkPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.dashboardSurfaceElevated),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: formState.expiresAt == null
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textOnDarkPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (formState.expiresAt != null)
                  GestureDetector(
                    onTap: () =>
                        context.read<PostListingCubit>().updateExpiresAt(null),
                    child: const Icon(Icons.close, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryPickerItem {
  final Category category;
  final int depth;

  const _CategoryPickerItem({required this.category, required this.depth});
}
