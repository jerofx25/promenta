part of 'auth_bloc.dart';

enum AuthFlowStatus { idle, loading, failure }

class AuthState extends Equatable {
  final bool authenticated;
  final UserProfile? profile;
  final AuthFlowStatus status;
  final String? error;

  const AuthState({
    required this.authenticated,
    required this.profile,
    required this.status,
    this.error,
  });

  const AuthState.initial()
      : authenticated = false,
        profile = null,
        status = AuthFlowStatus.idle,
        error = null;

  AuthState copyWith({
    bool? authenticated,
    UserProfile? profile,
    bool clearProfile = false,
    AuthFlowStatus? status,
    String? error,
  }) {
    return AuthState(
      authenticated: authenticated ?? this.authenticated,
      profile: clearProfile ? null : (profile ?? this.profile),
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [authenticated, profile, status, error];
}
