part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class _AuthStatusChanged extends AuthEvent {
  final bool isAuthenticated;
  const _AuthStatusChanged(this.isAuthenticated);
  @override
  List<Object?> get props => [isAuthenticated];
}

class _AuthProfileChanged extends AuthEvent {
  final UserProfile? profile;
  const _AuthProfileChanged(this.profile);
  @override
  List<Object?> get props => [profile];
}
