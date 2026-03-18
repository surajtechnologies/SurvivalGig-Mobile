import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart';

/// Profile state
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Loading state
class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Loaded state
class ProfileLoaded extends ProfileState {
  final Profile profile;
  final bool isUploadingImage;
  final bool isUploadingVerificationDocument;
  final String? statusMessage;
  final bool isStatusError;

  const ProfileLoaded({
    required this.profile,
    this.isUploadingImage = false,
    this.isUploadingVerificationDocument = false,
    this.statusMessage,
    this.isStatusError = false,
  });

  ProfileLoaded copyWith({
    Profile? profile,
    bool? isUploadingImage,
    bool? isUploadingVerificationDocument,
    String? statusMessage,
    bool? isStatusError,
    bool clearStatusMessage = false,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      isUploadingVerificationDocument:
          isUploadingVerificationDocument ??
          this.isUploadingVerificationDocument,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
      isStatusError: isStatusError ?? this.isStatusError,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    isUploadingImage,
    isUploadingVerificationDocument,
    statusMessage,
    isStatusError,
  ];
}

/// Error state
class ProfileError extends ProfileState {
  final String message;
  final String? code;

  const ProfileError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}
