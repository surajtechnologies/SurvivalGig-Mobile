import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../config/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/domain/entities/listing.dart';
import '../../domain/entities/trade_offer.dart';
import '../cubit/make_offer_cubit.dart';
import '../cubit/make_offer_state.dart';

/// Make offer screen
/// Uses BlocProvider pattern per copilot_instructions.md
class MakeOfferScreen extends StatelessWidget {
  final Listing listing;

  const MakeOfferScreen({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MakeOfferCubit(
        createTradeOfferUseCase: sl(),
        uploadItemImagesUseCase: sl(),
        listingId: listing.id,
      ),
      child: _MakeOfferView(listing: listing),
    );
  }
}

class _MakeOfferView extends StatefulWidget {
  final Listing listing;

  const _MakeOfferView({required this.listing});

  @override
  State<_MakeOfferView> createState() => _MakeOfferViewState();
}

class _MakeOfferViewState extends State<_MakeOfferView> {
  final _pointsController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _skillDescriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _pointsController.dispose();
    _itemDescriptionController.dispose();
    _skillDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        context.read<MakeOfferCubit>().addImage(pickedFile.path);
      }
    } catch (_) {
      // Error handled silently - no logging outside Dio interceptors
    }
  }

  void _showOfferTypeBottomSheet() {
    final cubit = context.read<MakeOfferCubit>();
    final state = cubit.state;
    if (state is! MakeOfferFormState) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _OfferTypeBottomSheet(
        selectedType: state.selectedOfferType,
        onSelected: (type) {
          cubit.updateOfferType(type);
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MakeOfferCubit, MakeOfferState>(
      listener: (context, state) {
        if (state is MakeOfferSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      },
      builder: (context, state) {
        if (state is MakeOfferFormState) {
          return Scaffold(
            backgroundColor: AppColors.white,
            appBar: _buildAppBar(),
            body: _buildBody(state),
            bottomNavigationBar: _buildSubmitButton(state),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Propose New Offer',
        style: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(MakeOfferFormState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User offering info
          Text(
            '${widget.listing.user.name} Offering',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.listing.title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // "I would like to request" label
          Text(
            'I would like to request',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Offer type dropdown
          _buildOfferTypeDropdown(state),
          const SizedBox(height: 16),

          // Conditional fields based on offer type
          _buildConditionalFields(state),

          // Error messages
          if (state.validationError != null) ...[
            const SizedBox(height: 8),
            Text(
              state.validationError!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          if (state.submitError != null) ...[
            const SizedBox(height: 8),
            Text(
              state.submitError!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOfferTypeDropdown(MakeOfferFormState state) {
    return GestureDetector(
      onTap: _showOfferTypeBottomSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              state.selectedOfferType.displayName,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionalFields(MakeOfferFormState state) {
    switch (state.selectedOfferType) {
      case OfferType.points:
        return _buildPointsField(state);
      case OfferType.item:
        return _buildItemFields(state);
      case OfferType.skill:
        return _buildSkillField(state);
    }
  }

  Widget _buildPointsField(MakeOfferFormState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _pointsController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: '100 pts',
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          suffixText: 'pts',
          suffixStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textPrimary,
        ),
        onChanged: (value) {
          final points = int.tryParse(value);
          context.read<MakeOfferCubit>().updatePoints(points);
        },
      ),
    );
  }

  Widget _buildItemFields(MakeOfferFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item description
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _itemDescriptionController,
                maxLines: 4,
                maxLength: 100,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Item Description',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  counterText: '',
                ),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                onChanged: (value) {
                  context.read<MakeOfferCubit>().updateItemDescription(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${state.itemDescriptionCharCount}/100',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Photos section
        _buildPhotosSection(state),
      ],
    );
  }

  Widget _buildPhotosSection(MakeOfferFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image error
        if (state.imageError != null) ...[
          Text(
            state.imageError!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Images row
        Row(
          children: [
            // Existing images
            ...List.generate(state.localImagePaths.length, (index) {
              final isUploading = state.isUploadingImage && 
                  state.uploadingImageIndex == index;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(state.localImagePaths[index])),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isUploading
                          ? Container(
                              decoration: BoxDecoration(
                                color: AppColors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
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
                            )
                          : null,
                    ),
                    if (!isUploading)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () => context.read<MakeOfferCubit>().removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.textPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),

            // Add photo button
            if (state.canAddMoreImages)
              GestureDetector(
                onTap: state.isUploadingImage ? null : _pickImage,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillField(MakeOfferFormState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _skillDescriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Skill Description',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            onChanged: (value) {
              context.read<MakeOfferCubit>().updateSkillDescription(value);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${state.skillDescriptionWordCount}/100',
              style: AppTextStyles.bodySmall.copyWith(
                color: state.skillDescriptionWordCount > 100
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(MakeOfferFormState state) {
    final isEnabled = state.isFormValid && !state.isSubmitting;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? () => context.read<MakeOfferCubit>().submitOffer() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? AppColors.primary : AppColors.lightGrey,
              foregroundColor: isEnabled ? AppColors.white : AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text(
                    'Make Offer',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for selecting offer type
class _OfferTypeBottomSheet extends StatelessWidget {
  final OfferType selectedType;
  final Function(OfferType) onSelected;

  const _OfferTypeBottomSheet({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              Text(
                'Offer',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Options
          _buildOption(context, OfferType.points),
          const SizedBox(height: 12),
          _buildOption(context, OfferType.item),
          const SizedBox(height: 12),
          _buildOption(context, OfferType.skill),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, OfferType type) {
    final isSelected = type == selectedType;

    return GestureDetector(
      onTap: () => onSelected(type),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            type.displayName,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
