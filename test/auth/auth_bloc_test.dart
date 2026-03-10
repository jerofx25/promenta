import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:IAEntrenar/blocs/auth/auth_bloc.dart';
import 'package:IAEntrenar/repositories/auth_repository.dart';
import 'package:IAEntrenar/models/user_profile.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<bool> authStateChanges() async* {
    yield false;
  }

  @override
  Stream<UserProfile?> currentUserProfile() async* {
    yield null;
  }

  @override
  Future<void> registerWithEmailAndPassword(
      String email, String password, String displayName, String phone) async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> signInWithEmailAndPassword(
      String email, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> updateUserFields(Map<String, dynamic> fields) async {}

  @override
  Future<String> uploadProfilePhoto(File file) async => 'https://example.com/photo.jpg';

  @override
  Future<void> updateUserProfile(UserProfile updatedProfile) async {}
}

void main() {
  group('AuthBloc', () {
    test('estado inicial no autenticado', () {
      final bloc = AuthBloc(authRepository: _FakeAuthRepository());
      expect(bloc.state.authenticated, false);
    });
  });
}


