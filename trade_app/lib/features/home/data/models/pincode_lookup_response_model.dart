/// API response model for Zippopotam US pincode lookup.
class PincodeLookupResponseModel {
  final String country;
  final String countryAbbreviation;
  final String postCode;
  final List<PincodePlaceModel> places;

  const PincodeLookupResponseModel({
    required this.country,
    required this.countryAbbreviation,
    required this.postCode,
    required this.places,
  });

  factory PincodeLookupResponseModel.fromJson(Map<String, dynamic> json) {
    final placesJson = json['places'] as List<dynamic>? ?? const [];

    return PincodeLookupResponseModel(
      country: json['country'] as String? ?? '',
      countryAbbreviation: json['country abbreviation'] as String? ?? '',
      postCode: json['post code'] as String? ?? '',
      places: placesJson
          .whereType<Map<String, dynamic>>()
          .map(PincodePlaceModel.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'country abbreviation': countryAbbreviation,
      'post code': postCode,
      'places': places.map((e) => e.toJson()).toList(),
    };
  }
}

class PincodePlaceModel {
  final String placeName;
  final String longitude;
  final String latitude;
  final String state;
  final String stateAbbreviation;

  const PincodePlaceModel({
    required this.placeName,
    required this.longitude,
    required this.latitude,
    required this.state,
    required this.stateAbbreviation,
  });

  factory PincodePlaceModel.fromJson(Map<String, dynamic> json) {
    return PincodePlaceModel(
      placeName: json['place name'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      state: json['state'] as String? ?? '',
      stateAbbreviation: json['state abbreviation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place name': placeName,
      'longitude': longitude,
      'latitude': latitude,
      'state': state,
      'state abbreviation': stateAbbreviation,
    };
  }
}
