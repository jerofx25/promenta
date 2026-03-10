import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';

import '../models/user_profile.dart';

/// Contract for authentication operations used by the application layer.
abstract class AuthRepository {
  /// Emits `true` when authenticated, `false` when unauthenticated.
  Stream<bool> authStateChanges();

  /// Emits the current user profile or null when signed out.
  Stream<UserProfile?> currentUserProfile();

  Future<void> signInWithEmailAndPassword(String email, String password);

  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    String phone,
  );

  Future<void> signOut();

  Future<void> updateUserProfile(UserProfile updatedProfile);

  Future<void> updateUserFields(Map<String, dynamic> fields);

  /// Sube la foto de perfil a Storage y devuelve la URL de descarga.
  Future<String> uploadProfilePhoto(File file);

  Future<void> resetPassword(String email);

  Future<void> deleteAccount();
}

class AuthStatusSnapshot extends Equatable {
  final bool isAuthenticated;
  final UserProfile? userProfile;

  const AuthStatusSnapshot({required this.isAuthenticated, this.userProfile});

  @override
  List<Object?> get props => [isAuthenticated, userProfile];
}
