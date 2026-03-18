/// Google mobile auth request model (DTO)
class GoogleMobileAuthRequestModel {
  final String idToken;

  const GoogleMobileAuthRequestModel({required this.idToken});

  Map<String, dynamic> toJson() {
    return {'idToken': idToken};
  }
}
