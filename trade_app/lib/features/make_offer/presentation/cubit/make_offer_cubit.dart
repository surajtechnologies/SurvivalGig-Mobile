import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trade_offer.dart';
import '../../domain/usecases/create_trade_offer_usecase.dart';
import '../../domain/usecases/upload_item_images_usecase.dart';
import 'make_offer_state.dart';

/// Make offer cubit
class MakeOfferCubit extends Cubit<MakeOfferState> {
  final CreateTradeOfferUseCase createTradeOfferUseCase;
  final UploadItemImagesUseCase uploadItemImagesUseCase;
  final String listingId;

  MakeOfferCubit({
    required this.createTradeOfferUseCase,
    required this.uploadItemImagesUseCase,
    required this.listingId,
  }) : super(const MakeOfferFormState());

  /// Get current form state
  MakeOfferFormState get _formState {
    final currentState = state;
    if (currentState is MakeOfferFormState) {
      return currentState;
    }
    return const MakeOfferFormState();
  }

  /// Update selected offer type
  void updateOfferType(OfferType type) {
    emit(_formState.copyWith(
      selectedOfferType: type,
      validationError: null,
      submitError: null,
    ));
  }

  /// Update points amount
  void updatePoints(int? points) {
    emit(_formState.copyWith(
      points: points,
      validationError: null,
    ));
  }

  /// Update item description
  void updateItemDescription(String description) {
    emit(_formState.copyWith(
      itemDescription: description,
      validationError: null,
    ));
  }

  /// Update skill description
  void updateSkillDescription(String description) {
    emit(_formState.copyWith(
      skillDescription: description,
      validationError: null,
    ));
  }

  /// Add image from file path
  Future<void> addImage(String filePath) async {
    final currentForm = _formState;

    if (!currentForm.canAddMoreImages) {
      emit(currentForm.copyWith(imageError: 'Maximum 3 photos allowed'));
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      emit(currentForm.copyWith(imageError: 'Image file not found'));
      return;
    }

    final newLocalPaths = [...currentForm.localImagePaths, filePath];
    final uploadingIndex = newLocalPaths.length - 1;

    emit(currentForm.copyWith(
      localImagePaths: newLocalPaths,
      isUploadingImage: true,
      uploadingImageIndex: uploadingIndex,
      imageError: null,
    ));

    try {
      // Read file and convert to base64 with MIME type prefix
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      final base64Image = 'data:image/jpeg;base64,$base64String';

      final result = await uploadItemImagesUseCase(base64Images: [base64Image]);

      result.fold(
        (failure) {
          final updatedLocalPaths = List<String>.from(_formState.localImagePaths);
          if (uploadingIndex < updatedLocalPaths.length) {
            updatedLocalPaths.removeAt(uploadingIndex);
          }

          emit(_formState.copyWith(
            localImagePaths: updatedLocalPaths,
            isUploadingImage: false,
            imageError: failure.message,
          ));
        },
        (urls) {
          final newUploadedUrls = [..._formState.uploadedImageUrls, ...urls];

          emit(_formState.copyWith(
            uploadedImageUrls: newUploadedUrls,
            isUploadingImage: false,
            imageError: null,
          ));
        },
      );
    } catch (e) {
      final updatedLocalPaths = List<String>.from(_formState.localImagePaths);
      if (uploadingIndex < updatedLocalPaths.length) {
        updatedLocalPaths.removeAt(uploadingIndex);
      }

      emit(_formState.copyWith(
        localImagePaths: updatedLocalPaths,
        isUploadingImage: false,
        imageError: 'Failed to upload image: ${e.toString()}',
      ));
    }
  }

  /// Remove image at index
  void removeImage(int index) {
    final currentForm = _formState;

    if (index < 0 || index >= currentForm.localImagePaths.length) return;

    final updatedLocalPaths = List<String>.from(currentForm.localImagePaths);
    updatedLocalPaths.removeAt(index);

    final updatedUrls = List<String>.from(currentForm.uploadedImageUrls);
    if (index < updatedUrls.length) {
      updatedUrls.removeAt(index);
    }

    emit(currentForm.copyWith(
      localImagePaths: updatedLocalPaths,
      uploadedImageUrls: updatedUrls,
      imageError: null,
    ));
  }

  /// Submit the offer
  Future<void> submitOffer() async {
    final currentForm = _formState;

    if (!currentForm.isFormValid) {
      emit(currentForm.copyWith(
        validationError: _getValidationError(currentForm),
      ));
      return;
    }

    emit(currentForm.copyWith(isSubmitting: true, submitError: null));

    // Build the request based on offer type
    OfferItem? offerItem;
    OfferSkill? offerSkill;
    int? offerPoints;

    switch (currentForm.selectedOfferType) {
      case OfferType.points:
        offerPoints = currentForm.points;
        break;
      case OfferType.item:
        offerItem = OfferItem(
          description: currentForm.itemDescription ?? '',
          images: currentForm.uploadedImageUrls,
        );
        break;
      case OfferType.skill:
        offerSkill = OfferSkill(
          description: currentForm.skillDescription ?? '',
        );
        break;
    }

    final request = TradeOfferRequest(
      listingId: listingId,
      offerType: currentForm.selectedOfferType,
      offerPoints: offerPoints,
      offerItem: offerItem,
      offerSkill: offerSkill,
    );

    final result = await createTradeOfferUseCase(request: request);

    result.fold(
      (failure) {
        emit(_formState.copyWith(
          isSubmitting: false,
          submitError: failure.message,
        ));
      },
      (trade) {
        emit(MakeOfferSuccess(tradeId: trade.id));
      },
    );
  }

  String _getValidationError(MakeOfferFormState form) {
    switch (form.selectedOfferType) {
      case OfferType.points:
        return 'Please enter a valid points amount';
      case OfferType.item:
        if (form.itemDescription == null || form.itemDescription!.isEmpty) {
          return 'Please enter an item description';
        }
        return 'Item description must be 100 characters or less';
      case OfferType.skill:
        if (form.skillDescription == null || form.skillDescription!.isEmpty) {
          return 'Please enter a skill description';
        }
        return 'Skill description must be 100 words or less';
    }
  }
}
