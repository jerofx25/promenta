import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../router/router_notifier.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, onboarding }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  AuthStatus _authStatus = AuthStatus.initial;
  UserProfile? _userProfile;
  int _onboardingStep = 0;
  final int _totalOnboardingSteps = 6;

  AuthProvider({required AuthService authService})
      : _authService = authService {
    _init();
  }

  AuthStatus get authStatus => _authStatus;
  UserProfile? get userProfile => _userProfile;
  int get onboardingStep => _onboardingStep;
  int get totalOnboardingSteps => _totalOnboardingSteps;

  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        // Usuario autenticado
        await _loadUserProfile(user);
      } else {
        // Usuario no autenticado
        _userProfile = null;
        _authStatus = AuthStatus.unauthenticated;
        _notifyAndUpdateRouter();
      }
    });
  }

  Future<void> _loadUserProfile(User user) async {
    try {
      // Aquí podrías cargar datos adicionales del usuario desde Firestore
      _userProfile = UserProfile(
        id: user.uid,
        displayName:
            user.displayName ?? user.email?.split('@').first ?? 'Usuario',
        email: user.email ?? '',
      );


      // Verificar si el usuario necesita completar el onboarding
      if (_userProfile!.age != null &&
          _userProfile!.weight != null &&
          _userProfile!.height != null &&
          _userProfile!.goals.isNotEmpty) {
        _authStatus = AuthStatus.authenticated;
      } else {
        _authStatus = AuthStatus.onboarding;
        _calculateOnboardingStep();
      }

      _notifyAndUpdateRouter();
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _notifyAndUpdateRouter();
    }

  }

  get profileImage => null;

  get name => null;

  get email => null;

  get height => null;

  get heightUnit => null;

  get injuries => null;

  get trainingFrequency => null;

  get fitnessGoal => null;

  get dietaryHabits => null;

  void _notifyAndUpdateRouter() {
    notifyListeners();
    routerNotifier.refresh();
  }

  void _calculateOnboardingStep() {
    if (_userProfile!.age == null) {
      _onboardingStep = 0;
    } else if (_userProfile!.weight == null) {
      _onboardingStep = 1;
    } else if (_userProfile!.height == null) {
      _onboardingStep = 2;
    } else if (_userProfile!.goals.isEmpty) {
      _onboardingStep = 3;
    } else if (_userProfile!.injuries.isEmpty) {
      _onboardingStep = 4;
    } else if (_userProfile!.trainingLevel == null) {
      _onboardingStep = 5;
    } else {
      _onboardingStep = 6;
    }
  }

  Future<void> _saveUserToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(_userProfile!.toJson()));
  }

  Future<bool> signIn(String email, String password) async {
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String displayName) async {
    try {
      await _authService.registerWithEmailAndPassword(
          email, password, displayName);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      _userProfile = UserProfile(
        id: 'google-user-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Google User',
        email: 'user@gmail.com',
      );

      await _saveUserToStorage();
      _authStatus = AuthStatus.onboarding;
      _onboardingStep = 0;
      _notifyAndUpdateRouter();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      _userProfile = UserProfile(
        id: 'apple-user-${DateTime.now().millisecondsSinceEpoch}',
        displayName: 'Apple User',
        email: 'user@icloud.com',
      );

      await _saveUserToStorage();
      _authStatus = AuthStatus.onboarding;
      _onboardingStep = 0;
      _notifyAndUpdateRouter();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return email.contains('@');
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _userProfile = null;
      _authStatus = AuthStatus.unauthenticated;
      _notifyAndUpdateRouter();
    } catch (e) {
      // Manejar error
    }
  }

  // Update user fields
  void _updateUserFields(Map<String, dynamic> fields) {
    _userProfile = _userProfile!.copyWith(
      age: fields['age'],
      weight: fields['weight'],
      height: fields['height'],
      trainingLevel: fields['trainingLevel'],
      goals: fields['goals'] != null ? List<String>.from(fields['goals']) : _userProfile!.goals,
      injuries: fields['injuries'] != null ? List<String>.from(fields['injuries']) : _userProfile!.injuries,
      photoUrl: fields['photoUrl'],
    );
    _saveUserToStorage();
    try {
      _authService.updateUserFields(fields);
    } catch (_) {}
    _notifyAndUpdateRouter();
  }

  // Onboarding setters
  void setAge(int age) {
    if(_userProfile?.age == null){
      _updateUserFields({'age': age});
    }
  }

  void setWeight(double weight) {
    if(_userProfile?.weight == null){
      _updateUserFields({'weight': weight});
    }
  }

  void setHeight(double height) {
    if(_userProfile?.height == null){
      _updateUserFields({'height': height});
    }
  }

  void setTrainingLevel(String level) {
    if(_userProfile?.trainingLevel == null){
      _updateUserFields({'trainingLevel': level});
    }
  }

  void setGoals(List<String> goals) {
    if(goals.isNotEmpty) _updateUserFields({'goals': goals});
  }

  void setInjuries(List<String> injuries) {
    if(injuries.isNotEmpty) _updateUserFields({'injuries': injuries});
  }

  void setPhotoUrl(String photoUrl) {
    if(_userProfile?.photoUrl == null){
      _updateUserFields({'photoUrl': photoUrl});
    }
  }

  void nextOnboardingStep() {
    if (_onboardingStep < _totalOnboardingSteps) {
      _onboardingStep++;
    }

    if (_onboardingStep >= _totalOnboardingSteps) {
      _authStatus = AuthStatus.authenticated;
    }

    _notifyAndUpdateRouter();
  }

  void previousOnboardingStep() {
    if (_onboardingStep > 0) {
      _onboardingStep--;
      _notifyAndUpdateRouter();
    }
  }

  void skipOnboarding() {
    _authStatus = AuthStatus.authenticated;
    _notifyAndUpdateRouter();
  }

  Future<void> updateUserFields(Map<String, dynamic> fields) async {
    try {
      await _authService.updateUserFields(fields);
    } catch (e) {
      rethrow;
    }
  }
}