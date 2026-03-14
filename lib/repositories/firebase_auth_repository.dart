import 'dart:async';
import 'dart:io';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final AuthService _authService;

  FirebaseAuthRepository(this._authService);

  @override
  Future<String> uploadProfilePhoto(File file) {
    return _authService.uploadProfilePhoto(file);
  }

  @override
  Stream<bool> authStateChanges() {
    return _authService.authStateChanges.map((user) => user != null);
  }

  @override
  Stream<UserProfile?> currentUserProfile() {
    return _authService.currentUserProfile;
  }

  @override
  Future<void> deleteAccount() {
    return _authService.deleteAccount();
  }

  @override
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    String phone,
  ) async {
    await _authService.registerWithEmailAndPassword(
      email,
      password,
      displayName,
      phone,
    );
  }

  @override
  Future<void> resetPassword(String email) {
    return _authService.resetPassword(email);
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _authService.signInWithEmailAndPassword(email, password);
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }

  @override
  Future<void> updateUserFields(Map<String, dynamic> fields) {
    return _authService.updateUserFields(fields);
  }

  @override
  Future<void> updateUserProfile(UserProfile updatedProfile) {
    return _authService.updateUserProfile(updatedProfile);
  }
}
