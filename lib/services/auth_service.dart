import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios en el estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener el perfil del usuario actual
  Stream<UserProfile?> get currentUserProfile {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<UserProfile?>.value(null);
      }

      return _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null)
          .handleError((e, stackTrace) {
            debugPrint('Error getting user profile stream: $e');
            debugPrint('$stackTrace');
            // No rethrow: evita Unhandled Exception. El stream sigue activo.
            // Si persiste permission-denied, revisa Firestore Rules y que el
            // documento users/<uid> exista y las reglas estén desplegadas.
          });
    });
  }

  // Registro con email y contraseña
  Future<UserCredential> registerWithEmailAndPassword(
      String email,
      String password,
      String displayName,
      String phone) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar el displayName en Auth
      await result.user?.updateDisplayName(displayName);

      // Crear documento del usuario en Firestore
      final userProfile = UserProfile(
        id: result.user!.uid,
        displayName: displayName,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        onboardingStep: 0,
        onboardingCompleted: false,
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(userProfile.toFirestore());

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Inicio de sesión con email y contraseña
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar lastLogin
      await _firestore.collection('users').doc(result.user!.uid).set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar perfil del usuario
  Future<void> updateUserProfile(UserProfile updatedProfile) async {
    try {
      if (currentUser != null) {
        // Actualizar Auth profile si el nombre ha cambiado
        if (currentUser!.displayName != updatedProfile.displayName) {
          await currentUser!.updateDisplayName(updatedProfile.displayName);
        }

        // Actualizar Firestore
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .set(updatedProfile.toFirestore(), SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Sube la foto de perfil a Storage y devuelve la URL de descarga.
  Future<String> uploadProfilePhoto(File file) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuario no autenticado');
    }
    final ref = _storage
        .ref()
        .child('users')
        .child(user.uid)
        .child('profile_photo.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // Actualizar campos específicos del perfil
  Future<void> updateUserFields(Map<String, dynamic> fields) async {
    try {
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .set(fields, SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar cuenta
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Eliminar datos de Firestore
        await _firestore.collection('users').doc(currentUser!.uid).delete();
        // Eliminar cuenta de Auth
        await currentUser!.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }
}
