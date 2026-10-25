import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _needsProfileSetup = false;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    _currentUser = _authService.currentUser;
    if (_currentUser != null) {
      _checkProfile(_currentUser!);
    } else {
      _isLoading = false;
    }

    _authSubscription = _authService.authStateChanges.listen((user) async {
      _currentUser = user;
      if (user != null) {
        await _checkProfile(user);
      } else {
        _userProfile = null;
        _needsProfileSetup = false;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _checkProfile(User user) async {
    _isLoading = true;
    notifyListeners();

    final profile = await _authService.fetchUserProfile(user.uid);
    _userProfile = profile;

    if (profile == null || !profile.isComplete) {
      _needsProfileSetup = true;
    } else {
      _needsProfileSetup = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  User? get currentUser => _currentUser;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _currentUser != null;
  bool get isFullyRegistered => isAuthenticated && !_needsProfileSetup;
  bool get needsProfileSetup => _needsProfileSetup;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get userId => _currentUser?.uid ?? 'guest';
  String get displayName => _userProfile?.name ?? _authService.displayName;
  String get phone => _userProfile?.phone ?? '';

  /// Google Sign-In as required
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred == null) {
        _setLoading(false);
        return false;
      }
      _currentUser = cred.user;
      if (_currentUser != null) {
        await _checkProfile(_currentUser!);
      }
      return true;
    } catch (e) {
      _errorMessage = 'Google sign-in error: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  /// Save profile details (Name, Phone, Town)
  Future<bool> saveProfile({
    required String name,
    required String phone,
    required String town,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    _errorMessage = null;

    try {
      final profile = UserProfile(
        uid: _currentUser!.uid,
        name: name.trim(),
        email: _currentUser!.email ?? '',
        phone: phone.trim(),
        town: town.trim(),
        photoUrl: _currentUser!.photoURL,
        createdAt: _userProfile?.createdAt ?? DateTime.now(),
      );

      await _authService.saveUserProfile(profile);
      _userProfile = profile;
      _needsProfileSetup = false;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save profile: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _currentUser = null;
      _userProfile = null;
      _needsProfileSetup = false;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
