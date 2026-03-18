import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/create_listing.dart';
import '../../domain/usecases/create_listing_usecase.dart';
import '../../domain/usecases/get_city_by_zipcode_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/upload_images_usecase.dart';
import 'post_listing_state.dart';

/// Post listing cubit
/// Handles form state, image uploads, and listing creation
class PostListingCubit extends Cubit<PostListingState> {
  final CreateListingUseCase createListingUseCase;
  final UploadImagesUseCase uploadImagesUseCase;
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetCityByZipcodeUseCase getCityByZipcodeUseCase;
  Timer? _zipcodeDebounce;
  int _locationLookupRequestId = 0;

  PostListingCubit({
    required this.createListingUseCase,
    required this.uploadImagesUseCase,
    required this.getCategoriesUseCase,
    required this.getCityByZipcodeUseCase,
  }) : super(const PostListingFormState()) {
    // Load categories on initialization
    loadCategories();
  }

  /// Get current form state
  PostListingFormState get _formState {
    final currentState = state;
    if (currentState is PostListingFormState) {
      return currentState;
    }
    if (currentState is PostListingSubmitting) {
      return currentState.formData;
    }
    if (currentState is PostListingError) {
      return currentState.formData;
    }
    return const PostListingFormState();
  }

  /// Load categories from API
  Future<void> loadCategories() async {
    emit(_formState.copyWith(isLoadingCategories: true, categoriesError: null));

    final result = await getCategoriesUseCase();

    result.fold(
      (failure) {
        emit(
          _formState.copyWith(
            isLoadingCategories: false,
            categoriesError: failure.message,
          ),
        );
      },
      (categories) {
        emit(
          _formState.copyWith(
            isLoadingCategories: false,
            categories: categories,
            categoriesError: null,
          ),
        );
      },
    );
  }

  /// Update listing type (ITEM_OFFERING, SERVICE_OFFERING, etc.)
  void updateListingType(ListingType listingType) {
    emit(_formState.copyWith(listingType: listingType));
  }

  /// Update title
  void updateTitle(String title) {
    emit(_formState.copyWith(title: title, validationError: null));
  }

  /// Update description
  void updateDescription(String description) {
    emit(_formState.copyWith(description: description, validationError: null));
  }

  /// Update category
  void updateCategory(String? categoryId) {
    emit(_formState.copyWith(categoryId: categoryId, validationError: null));
  }

  /// Update condition
  void updateCondition(String? condition) {
    emit(_formState.copyWith(condition: condition, validationError: null));
  }

  /// Update zipcode and resolve city
  void updateLocation(String location) {
    final zipcode = location.trim();
    // Invalidate any in-flight zipcode lookup when input changes.
    _locationLookupRequestId++;
    final requestId = _locationLookupRequestId;

    if (zipcode.isEmpty) {
      _zipcodeDebounce?.cancel();
      emit(
        _formState.copyWith(
          location: '',
          clearLocationCity: true,
          isResolvingLocationCity: false,
          clearLocationCityError: true,
          validationError: null,
        ),
      );
      return;
    }

    final hasValidFormat = RegExp(r'^\d{5,9}$').hasMatch(zipcode);
    emit(
      _formState.copyWith(
        location: zipcode,
        isResolvingLocationCity: hasValidFormat,
        clearLocationCityError: true,
        validationError: null,
        clearLocationCity: !hasValidFormat,
      ),
    );

    _zipcodeDebounce?.cancel();

    if (!hasValidFormat) {
      return;
    }

    _zipcodeDebounce = Timer(const Duration(milliseconds: 350), () {
      _resolveLocationCity(zipcode, requestId);
    });
  }

  /// Update price mode (POINTS/SKILL)
  void updatePriceMode(PriceMode priceMode) {
    emit(_formState.copyWith(priceMode: priceMode));
  }

  /// Update price points
  void updatePricePoints(String pricePoints) {
    emit(_formState.copyWith(pricePoints: pricePoints, validationError: null));
  }

  /// Update barter wanted description
  void updateBarterWanted(String barterWanted) {
    emit(
      _formState.copyWith(barterWanted: barterWanted, validationError: null),
    );
  }

  /// Add image from file path - converts to base64 and uploads
  Future<void> addImage(String filePath) async {
    final currentForm = _formState;

    // Check if we can add more images (max 3)
    if (!currentForm.canAddMoreImages) {
      emit(currentForm.copyWith(imageError: 'Maximum 3 photos allowed'));
      return;
    }

    // Verify file exists
    final file = File(filePath);
    if (!await file.exists()) {
      emit(currentForm.copyWith(imageError: 'Image file not found'));
      return;
    }

    // Add local path and start uploading
    final newLocalPaths = [...currentForm.localImagePaths, filePath];
    final uploadingIndex = newLocalPaths.length - 1;

    emit(
      currentForm.copyWith(
        localImagePaths: newLocalPaths,
        isUploadingImage: true,
        uploadingImageIndex: uploadingIndex,
        imageError: null,
      ),
    );

    try {
      // Read file and convert to base64 with MIME type prefix
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final base64Image = 'data:image/jpeg;base64,$base64String';

      // Upload image to server
      final result = await uploadImagesUseCase(base64Images: [base64Image]);

      result.fold(
        (failure) {
          // Remove the local path on failure
          final updatedLocalPaths = List<String>.from(
            _formState.localImagePaths,
          );
          if (uploadingIndex < updatedLocalPaths.length) {
            updatedLocalPaths.removeAt(uploadingIndex);
          }

          emit(
            _formState.copyWith(
              localImagePaths: updatedLocalPaths,
              isUploadingImage: false,
              imageError: failure.message,
            ),
          );
        },
        (urls) {
          // Add uploaded URL to list
          final newUploadedUrls = [..._formState.uploadedImageUrls, ...urls];

          emit(
            _formState.copyWith(
              uploadedImageUrls: newUploadedUrls,
              isUploadingImage: false,
              imageError: null,
            ),
          );
        },
      );
    } catch (e) {
      // Remove the local path on error
      final updatedLocalPaths = List<String>.from(_formState.localImagePaths);
      if (uploadingIndex < updatedLocalPaths.length) {
        updatedLocalPaths.removeAt(uploadingIndex);
      }

      emit(
        _formState.copyWith(
          localImagePaths: updatedLocalPaths,
          isUploadingImage: false,
          imageError: 'Failed to upload image: ${e.toString()}',
        ),
      );
    }
  }

  /// Remove image at index
  void removeImage(int index) {
    final currentForm = _formState;

    if (index < 0) return;

    final newUploadedUrls = List<String>.from(currentForm.uploadedImageUrls);
    final newLocalPaths = List<String>.from(currentForm.localImagePaths);

    if (index < newUploadedUrls.length) {
      newUploadedUrls.removeAt(index);
    }

    if (index < newLocalPaths.length) {
      newLocalPaths.removeAt(index);
    }

    emit(
      currentForm.copyWith(
        uploadedImageUrls: newUploadedUrls,
        localImagePaths: newLocalPaths,
        imageError: null,
      ),
    );
  }

  /// Clear image error
  void clearImageError() {
    emit(_formState.copyWith(imageError: null));
  }

  /// Submit listing
  Future<void> submitListing() async {
    final currentForm = _formState;

    // Validate form
    if (!currentForm.isFormValid) {
      String? validationError;

      if (currentForm.title.trim().isEmpty) {
        validationError = 'Title is required';
      } else if (currentForm.title.trim().length < 3) {
        validationError = 'Title must be at least 3 characters';
        // TODO: Re-enable image check once upload is fixed
        // } else if (currentForm.uploadedImageUrls.isEmpty) {
        //   validationError = 'At least one photo is required';
      } else if (currentForm.categoryId == null ||
          currentForm.categoryId!.isEmpty) {
        validationError = 'Please select a category';
      } else if (currentForm.priceMode == PriceMode.points &&
          (int.tryParse(currentForm.pricePoints) == null ||
              int.parse(currentForm.pricePoints) <= 0)) {
        validationError = 'Please enter valid points';
      } else if (currentForm.priceMode == PriceMode.skill &&
          currentForm.barterWanted.trim().isEmpty) {
        validationError = 'Please enter what you want in exchange';
      } else if (currentForm.location.trim().isEmpty) {
        validationError = 'Zipcode is required';
      } else if (!RegExp(r'^\d{5,9}$').hasMatch(currentForm.location.trim())) {
        validationError = 'Please enter a valid 5 to 9-digit zipcode';
      } else if (currentForm.locationCity == null ||
          currentForm.locationCity!.trim().isEmpty) {
        validationError =
            currentForm.locationCityError ??
            'City not found for the entered zipcode';
      } else if (currentForm.description.trim().isEmpty) {
        validationError = 'Description is required';
      }

      emit(currentForm.copyWith(validationError: validationError));
      return;
    }

    // Start submitting
    emit(PostListingSubmitting(formData: currentForm));

    // Create request with uploaded image URLs
    final request = CreateListingRequest(
      type: currentForm.listingType,
      title: currentForm.title.trim(),
      description: currentForm.description.trim(),
      categoryId: currentForm.categoryId,
      condition: currentForm.condition,
      location: currentForm.locationCity?.trim() ?? currentForm.location.trim(),
      priceMode: currentForm.priceMode,
      pricePoints: currentForm.priceMode == PriceMode.points
          ? int.parse(currentForm.pricePoints)
          : null,
      barterWanted: currentForm.priceMode == PriceMode.skill
          ? currentForm.barterWanted.trim()
          : null,
      photos: currentForm.uploadedImageUrls,
    );

    // Submit
    final result = await createListingUseCase(request: request);

    result.fold(
      (failure) {
        emit(
          PostListingError(
            message: failure.message,
            code: failure.code,
            formData: currentForm,
          ),
        );
      },
      (listing) {
        emit(PostListingSuccess(listing: listing));
      },
    );
  }

  /// Reset form
  void resetForm() {
    emit(const PostListingFormState());
  }

  /// Retry after error
  void retryFromError() {
    final currentState = state;
    if (currentState is PostListingError) {
      emit(currentState.formData);
    }
  }

  Future<void> _resolveLocationCity(String zipcode, int requestId) async {
    final result = await getCityByZipcodeUseCase(zipcode: zipcode);

    if (requestId != _locationLookupRequestId) {
      return;
    }

    result.fold(
      (failure) {
        emit(
          _formState.copyWith(
            clearLocationCity: true,
            isResolvingLocationCity: false,
            locationCityError: failure.message,
          ),
        );
      },
      (city) {
        emit(
          _formState.copyWith(
            locationCity: city,
            isResolvingLocationCity: false,
            clearLocationCityError: true,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _zipcodeDebounce?.cancel();
    return super.close();
  }
}
