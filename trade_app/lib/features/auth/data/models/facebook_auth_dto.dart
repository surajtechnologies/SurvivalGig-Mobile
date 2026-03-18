/// Facebook mobile auth request model (DTO)
class FacebookMobileAuthRequestModel {
  final String accessToken;

  const FacebookMobileAuthRequestModel({required this.accessToken});

  Map<String, dynamic> toJson() {
    return {'accessToken': accessToken};
  }
}
