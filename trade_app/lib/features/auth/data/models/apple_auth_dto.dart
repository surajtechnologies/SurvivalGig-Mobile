/// Apple mobile auth request model (DTO)
class AppleMobileAuthRequestModel {
  final String identityToken;
  final String authorizationCode;
  final String? email;
  final String? firstName;
  final String? lastName;

  const AppleMobileAuthRequestModel({
    required this.identityToken,
    required this.authorizationCode,
    this.email,
    this.firstName,
    this.lastName,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'identityToken': identityToken,
      'authorizationCode': authorizationCode,
    };

    // Apple only provides user info on first sign-in
    if (email != null || firstName != null || lastName != null) {
      json['user'] = {
        'email': email ?? '',
        'name': {
          'firstName': firstName ?? '',
          'lastName': lastName ?? '',
        },
      };
    }

    return json;
  }
}
