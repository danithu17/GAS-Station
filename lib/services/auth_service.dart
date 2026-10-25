import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersRef => _firestore.collection('users');

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isAuthenticated => _auth.currentUser != null;

  String get userId => _auth.currentUser?.uid ?? 'guest';

  String get displayName {
    final user = _auth.currentUser;
    if (user == null) return 'Guest';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return user.email?.split('@').first ?? 'Citizen User';
  }

  /// Sign in with Google Account
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('Signed in with Google: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-in error: $e');
      rethrow;
    }
  }

  /// Fetch user profile from Firestore collection `users`
  Future<UserProfile?> fetchUserProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Save or update user profile to Firestore
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _usersRef.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
      debugPrint('User profile saved for: ${profile.name} (${profile.phone})');
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}
