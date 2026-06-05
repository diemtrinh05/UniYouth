abstract class AuthTokenProvider {
  Future<String?> getAccessToken();
}

class InMemoryAuthTokenProvider implements AuthTokenProvider {
  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  @override
  Future<String?> getAccessToken() async {
    return _accessToken;
  }
}
