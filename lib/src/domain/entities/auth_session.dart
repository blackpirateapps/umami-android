final class AuthSession {
  const AuthSession({
    required this.baseUrl,
    required this.token,
    required this.username,
    required this.createdAt,
    this.password,
  });

  final String baseUrl;
  final String token;
  final String username;
  final String? password;
  final DateTime createdAt;

  bool get canRefreshWithoutPrompt => password != null && password!.isNotEmpty;

  AuthSession copyWith({
    String? baseUrl,
    String? token,
    String? username,
    String? password,
    DateTime? createdAt,
  }) {
    return AuthSession(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

final class LoginCommand {
  const LoginCommand({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.storeCredentialsForRefresh = true,
  });

  final String baseUrl;
  final String username;
  final String password;
  final bool storeCredentialsForRefresh;
}
