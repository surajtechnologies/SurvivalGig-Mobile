import 'package:equatable/equatable.dart';
import '../../../../shared/models/category.dart';
import '../../domain/entities/create_listing.dart';

/// Post listing states
sealed class PostListingState extends Equatable {
  const PostListingState();

  @override
  List<Object?> get props => [];
}

/// Initial state with empty form
class PostListingInitial extends PostListingState {
  const PostListingInitial();
}

/// Form state - tracks all form data and validation
class PostListingFormState extends PostListingState {
  final ListingType listingType;
  final String title;
  final String description;
  final String? categoryId;
  final String? condition;
  final String location;
  final String? locationCity;
  final bool isResolvingLocationCity;
  final String? locationCityError;
  final PriceMode priceMode;
  final String pricePoints;
  final String barterWanted;

  /// Available categories fetched from API
  final List<Category> categories;
  final bool isLoadingCategories;
  final String? categoriesError;

  /// List of uploaded image URLs from server
  final List<String> uploadedImageUrls;

  /// Local file paths for preview
  final List<String> localImagePaths;
  final bool isUploadingImage;
  final int? uploadingImageIndex;
  final String? imageError;
  final String? validationError;

  const PostListingFormState({
    this.listingType = ListingType.itemOffering,
    this.title = '',
    this.description = '',
    this.categoryId,
    this.condition,
    this.location = '',
    this.locationCity,
    this.isResolvingLocationCity = false,
    this.locationCityError,
    this.priceMode = PriceMode.points,
    this.pricePoints = '',
    this.barterWanted = '',
    this.categories = const [],
    this.isLoadingCategories = false,
    this.categoriesError,
    this.uploadedImageUrls = const [],
    this.localImagePaths = const [],
    this.isUploadingImage = false,
    this.uploadingImageIndex,
    this.imageError,
    this.validationError,
  });

  PostListingFormState copyWith({
    ListingType? listingType,
    String? title,
    String? description,
    String? categoryId,
    String? condition,
    String? location,
    String? locationCity,
    bool clearLocationCity = false,
    bool? isResolvingLocationCity,
    String? locationCityError,
    bool clearLocationCityError = false,
    PriceMode? priceMode,
    String? pricePoints,
    String? barterWanted,
    List<Category>? categories,
    bool? isLoadingCategories,
    String? categoriesError,
    List<String>? uploadedImageUrls,
    List<String>? localImagePaths,
    bool? isUploadingImage,
    int? uploadingImageIndex,
    String? imageError,
    String? validationError,
  }) {
    return PostListingFormState(
      listingType: listingType ?? this.listingType,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      locationCity: clearLocationCity
          ? null
          : (locationCity ?? this.locationCity),
      isResolvingLocationCity:
          isResolvingLocationCity ?? this.isResolvingLocationCity,
      locationCityError: clearLocationCityError
          ? null
          : (locationCityError ?? this.locationCityError),
      priceMode: priceMode ?? this.priceMode,
      pricePoints: pricePoints ?? this.pricePoints,
      barterWanted: barterWanted ?? this.barterWanted,
      categories: categories ?? this.categories,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      categoriesError: categoriesError,
      uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      uploadingImageIndex: uploadingImageIndex,
      imageError: imageError,
      validationError: validationError,
    );
  }

  /// Check if form is valid for submission
  bool get isFormValid {
    final hasRequiredFields =
        title.trim().isNotEmpty &&
        title.trim().length >= 3 &&
        description.trim().isNotEmpty &&
        categoryId != null &&
        categoryId!.isNotEmpty &&
        location.trim().isNotEmpty &&
        RegExp(r'^\d{5,9}$').hasMatch(location.trim()) &&
        locationCity != null &&
        locationCity!.trim().isNotEmpty;
    // TODO: Re-enable image check once upload is fixed
    // && uploadedImageUrls.isNotEmpty;

    // If price mode is points, we need valid points
    if (priceMode == PriceMode.points) {
      return hasRequiredFields &&
          int.tryParse(pricePoints) != null &&
          int.parse(pricePoints) > 0;
    }

    // If price mode is skill, we need exchange description
    if (priceMode == PriceMode.skill) {
      return hasRequiredFields && barterWanted.trim().isNotEmpty;
    }

    return hasRequiredFields;
  }

  /// Check if we can add more images (max 3)
  bool get canAddMoreImages => localImagePaths.length < 3;

  /// Get the count of images
  int get imageCount => localImagePaths.length;

  /// Get selected category name
  String? get selectedCategoryName {
    if (categoryId == null) return null;
    final category = categories.where((c) => c.id == categoryId).firstOrNull;
    return category?.name;
  }

  @override
  List<Object?> get props => [
    listingType,
    title,
    description,
    categoryId,
    condition,
    location,
    locationCity,
    isResolvingLocationCity,
    locationCityError,
    priceMode,
    pricePoints,
    barterWanted,
    categories,
    isLoadingCategories,
    categoriesError,
    uploadedImageUrls,
    localImagePaths,
    isUploadingImage,
    uploadingImageIndex,
    imageError,
    validationError,
  ];
}

/// Submitting state - when creating the listing
class PostListingSubmitting extends PostListingState {
  final PostListingFormState formData;

  const PostListingSubmitting({required this.formData});

  @override
  List<Object?> get props => [formData];
}

/// Success state - listing created successfully
class PostListingSuccess extends PostListingState {
  final CreatedListing listing;

  const PostListingSuccess({required this.listing});

  @override
  List<Object?> get props => [listing];
}

/// Error state - failed to create listing
class PostListingError extends PostListingState {
  final String message;
  final String? code;
  final PostListingFormState formData;

  const PostListingError({
    required this.message,
    this.code,
    required this.formData,
  });

  @override
  List<Object?> get props => [message, code, formData];
}
