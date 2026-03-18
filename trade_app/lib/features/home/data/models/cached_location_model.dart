/// Local cache model for storing selected location.
class CachedLocationModel {
  final String city;
  final String pincode;

  const CachedLocationModel({required this.city, required this.pincode});

  factory CachedLocationModel.fromJson(Map<String, dynamic> json) {
    return CachedLocationModel(
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'city': city, 'pincode': pincode};
  }
}
