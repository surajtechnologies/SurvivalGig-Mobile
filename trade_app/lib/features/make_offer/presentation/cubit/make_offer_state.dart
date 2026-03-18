import '../../domain/entities/trade_offer.dart';

/// Make offer state
abstract class MakeOfferState {
  const MakeOfferState();
}

/// Form state for make offer
class MakeOfferFormState extends MakeOfferState {
  final OfferType selectedOfferType;
  final int? points;
  final String? itemDescription;
  final List<String> localImagePaths;
  final List<String> uploadedImageUrls;
  final String? skillDescription;
  final bool isUploadingImage;
  final int? uploadingImageIndex;
  final String? imageError;
  final String? validationError;
  final bool isSubmitting;
  final String? submitError;

  const MakeOfferFormState({
    this.selectedOfferType = OfferType.points,
    this.points,
    this.itemDescription,
    this.localImagePaths = const [],
    this.uploadedImageUrls = const [],
    this.skillDescription,
    this.isUploadingImage = false,
    this.uploadingImageIndex,
    this.imageError,
    this.validationError,
    this.isSubmitting = false,
    this.submitError,
  });

  /// Check if form is valid for submission
  bool get isFormValid {
    switch (selectedOfferType) {
      case OfferType.points:
        return points != null && points! > 0;
      case OfferType.item:
        return itemDescription != null && 
               itemDescription!.isNotEmpty && 
               itemDescription!.length <= 100;
      case OfferType.skill:
        if (skillDescription == null || skillDescription!.isEmpty) return false;
        final wordCount = skillDescription!.split(RegExp(r'\s+')).length;
        return wordCount <= 100;
    }
  }

  /// Check if can add more images (max 3)
  bool get canAddMoreImages => localImagePaths.length < 3;

  /// Get description char count for item
  int get itemDescriptionCharCount => itemDescription?.length ?? 0;

  /// Get word count for skill description
  int get skillDescriptionWordCount {
    if (skillDescription == null || skillDescription!.isEmpty) return 0;
    return skillDescription!.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  MakeOfferFormState copyWith({
    OfferType? selectedOfferType,
    int? points,
    String? itemDescription,
    List<String>? localImagePaths,
    List<String>? uploadedImageUrls,
    String? skillDescription,
    bool? isUploadingImage,
    int? uploadingImageIndex,
    String? imageError,
    String? validationError,
    bool? isSubmitting,
    String? submitError,
  }) {
    return MakeOfferFormState(
      selectedOfferType: selectedOfferType ?? this.selectedOfferType,
      points: points ?? this.points,
      itemDescription: itemDescription ?? this.itemDescription,
      localImagePaths: localImagePaths ?? this.localImagePaths,
      uploadedImageUrls: uploadedImageUrls ?? this.uploadedImageUrls,
      skillDescription: skillDescription ?? this.skillDescription,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      uploadingImageIndex: uploadingImageIndex ?? this.uploadingImageIndex,
      imageError: imageError,
      validationError: validationError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
    );
  }
}

/// Success state after offer is created
class MakeOfferSuccess extends MakeOfferState {
  final String tradeId;
  final String message;

  const MakeOfferSuccess({
    required this.tradeId,
    this.message = 'Offer sent successfully!',
  });
}
