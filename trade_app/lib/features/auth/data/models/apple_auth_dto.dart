/// Apple mobile auth request model (DTO)
class AppleMobileAuthRequestModel {
  final String identityToken;
  final String authorizationCode;

  const AppleMobileAuthRequestModel({
    required this.identityToken,
    required this.authorizationCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
    };
  }
}
