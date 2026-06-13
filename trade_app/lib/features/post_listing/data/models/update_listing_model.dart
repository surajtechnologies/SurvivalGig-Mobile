import '../../domain/entities/update_listing.dart';

class UpdateListingRequestModel {
  final String listingId;
  final String title;
  final int? pricePoints;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? urgencyLevel;
  final DateTime? expiresAt;
  final List<String> deletePhotoIds;

  const UpdateListingRequestModel({
    required this.listingId,
    required this.title,
    required this.pricePoints,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.urgencyLevel,
    required this.expiresAt,
    required this.deletePhotoIds,
  });

  factory UpdateListingRequestModel.fromEntity(UpdateListingRequest entity) {
    return UpdateListingRequestModel(
      listingId: entity.listingId,
      title: entity.title,
      pricePoints: entity.pricePoints,
      description: entity.description,
      latitude: entity.latitude,
      longitude: entity.longitude,
      urgencyLevel: entity.urgencyLevel,
      expiresAt: entity.expiresAt,
      deletePhotoIds: entity.deletePhotoIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (pricePoints != null) 'pricePoints': pricePoints,
      'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'urgencyLevel': urgencyLevel,
      'expiresAt': expiresAt == null ? null : _dateOnlyUtc(expiresAt!),
      'deletePhotoIds': deletePhotoIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(),
    };
  }

  String _dateOnlyUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day).toIso8601String();
  }
}
