import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../router/router_notifier.dart'; // Aquí está la instancia válida y única

enum AuthStatus { initial, authenticated, unauthenticated, onboarding }

class AuthProvider extends ChangeNotifier {
  AuthStatus _authStatus = AuthStatus.initial;
  UserProfile? _userProfile;
  int _onboardingStep = 0;
  final int _totalOnboardingSteps = 6;

  AppRouterNotifier? _routerNotifier;

  AuthStatus get authStatus => _authStatus;
  UserProfile? get userProfile => _userProfile;
  int get onboardingStep => _onboardingStep;
  int get totalOnboardingSteps => _totalOnboardingSteps;

  AuthProvider() {
    _loadUserFromStorage();
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

  void setRouterNotifier(AppRouterNotifier routerNotifier) {
    _routerNotifier = routerNotifier;
  }

  void _notifyAndUpdateRouter() {
    notifyListeners();
    _routerNotifier?.refresh();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      try {
        _userProfile = UserProfile.fromJson(json.decode(userData));

        if (_userProfile!.age != null &&
            _userProfile!.weight != null &&
            _userProfile!.height != null &&
            _userProfile!.fitnessGoal != null) {
          _authStatus = AuthStatus.authenticated;
        } else {
          _authStatus = AuthStatus.onboarding;
          _calculateOnboardingStep();
        }
      } catch (e) {
        _authStatus = AuthStatus.unauthenticated;
      }
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }

    _notifyAndUpdateRouter();
  }

  void _calculateOnboardingStep() {
    if (_userProfile!.age == null) {
      _onboardingStep = 0;
    } else if (_userProfile!.weight == null) {
      _onboardingStep = 1;
    } else if (_userProfile!.height == null) {
      _onboardingStep = 2;
    } else if (_userProfile!.fitnessGoal == null ||
        _userProfile!.trainingFrequency == null) {
      _onboardingStep = 3;
    } else if (_userProfile!.injuries.isEmpty) {
      _onboardingStep = 4;
    } else if (_userProfile!.dietaryHabits.isEmpty) {
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
      await Future.delayed(const Duration(seconds: 1));
      if (email.contains('@') && password.length >= 6) {
        _userProfile = UserProfile(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: email.split('@').first,
        );

        await _saveUserToStorage();
        _authStatus = AuthStatus.authenticated;
        _notifyAndUpdateRouter();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (email.contains('@') && password.length >= 6) {
        _userProfile = UserProfile(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: name.isNotEmpty ? name : email.split('@').first,
        );

        await _saveUserToStorage();
        _authStatus = AuthStatus.onboarding;
        _onboardingStep = 0;
        _notifyAndUpdateRouter();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      _userProfile = UserProfile(
        id: 'google-user-${DateTime.now().millisecondsSinceEpoch}',
        email: 'user@gmail.com',
        name: 'Google User',
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
        email: 'user@icloud.com',
        name: 'Apple User',
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    _userProfile = null;
    _authStatus = AuthStatus.unauthenticated;
    _notifyAndUpdateRouter();
  }

  // Onboarding setters
  void setAge(int age) {
    _userProfile = _userProfile!.copyWith(age: age);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
  }

  void setWeight(double weight, String unit) {
    _userProfile = _userProfile!.copyWith(weight: weight, weightUnit: unit);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
  }

  void setHeight(double height, String unit) {
    _userProfile = _userProfile!.copyWith(height: height, heightUnit: unit);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
  }

  void setTrainingFrequency(String frequency) {
    _userProfile = _userProfile!.copyWith(trainingFrequency: frequency);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
  }

  void setFitnessGoal(String goal) {
    _userProfile = _userProfile!.copyWith(fitnessGoal: goal);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
  }

  void setInjuries(List<String> injuries) {
    _userProfile = _userProfile!.copyWith(injuries: injuries);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
  }

  void setDietaryHabits(List<String> habits) {
    _userProfile = _userProfile!.copyWith(dietaryHabits: habits);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
  }

  void setProfileImage(String imageUrl) {
    _userProfile = _userProfile!.copyWith(profileImageUrl: imageUrl);
    _saveUserToStorage();
    _notifyAndUpdateRouter();
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
}
