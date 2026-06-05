enum AuthBootstrapStatus {
  authenticated,
  unauthenticated,
}

abstract class AuthBootstrapRepository {
  Future<AuthBootstrapStatus> bootstrap();

  Future<bool> hasLocalSession();
}
