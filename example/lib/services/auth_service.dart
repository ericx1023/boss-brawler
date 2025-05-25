import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For Flutter Web, use clientId instead of serverClientId
    clientId: '750386372057-4caqt2k16av0sbdrubn9bjs4rm4d6ltp.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is signed in
  bool get isSignedIn => currentUser != null;
  
  // Check if user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Sign in anonymously for quick trial experience
  Future<UserCredential?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      await _createUserProfile(result.user!);
      return result;
    } catch (e) {
      debugPrint('Anonymous sign in failed: $e');
      return null;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign In...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign In cancelled by user');
        return null; // User cancelled
      }

      debugPrint('Google user obtained: ${googleUser.email}');
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // For Flutter Web, tokens might be null even when authentication succeeds
      // Try to get tokens with retry mechanism
      String? accessToken = googleAuth.accessToken;
      String? idToken = googleAuth.idToken;
      
      // Retry mechanism for Web platform
      if (accessToken == null || idToken == null) {
        debugPrint('Initial token fetch failed, retrying...');
        await Future.delayed(const Duration(milliseconds: 500));
        final retryAuth = await googleUser.authentication;
        accessToken = retryAuth.accessToken;
        idToken = retryAuth.idToken;
      }
      
      if (accessToken == null || idToken == null) {
        debugPrint('Failed to get Google auth tokens after retry');
        debugPrint('AccessToken: ${accessToken != null ? "present" : "null"}');
        debugPrint('IdToken: ${idToken != null ? "present" : "null"}');
        
        // For Web, try to continue with available token
        if (accessToken != null || idToken != null) {
          debugPrint('Attempting to continue with partial tokens...');
        } else {
          return null;
        }
      }
      
      debugPrint('Google auth tokens obtained successfully');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      debugPrint('Attempting Firebase sign in with Google credential...');
      final result = await _auth.signInWithCredential(credential);
      
      debugPrint('Firebase sign in successful: ${result.user?.email}');
      await _createUserProfile(result.user!);
      return result;
    } catch (e) {
      debugPrint('Google sign in failed with error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      debugPrint('Email sign in failed: $e');
      return null;
    }
  }

  /// Register with email and password
  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await result.user!.updateDisplayName(name);
      await _createUserProfile(result.user!, name: name);
      
      return result;
    } catch (e) {
      debugPrint('Email registration failed: $e');
      return null;
    }
  }

  /// Upgrade anonymous account to permanent account
  Future<UserCredential?> linkWithGoogle() async {
    if (!isAnonymous) return null;
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await currentUser!.linkWithCredential(credential);
      await _updateUserProfile(result.user!);
      return result;
    } catch (e) {
      debugPrint('Account linking failed: $e');
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }

  /// Delete account and all user data
  Future<bool> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Delete user data from Firestore
      await _deleteUserData(user.uid);
      
      // Delete the user account
      await user.delete();
      return true;
    } catch (e) {
      debugPrint('Account deletion failed: $e');
      return false;
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(User user, {String? name}) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final exists = await userDoc.get();
      
      if (!exists.exists) {
        await userDoc.set({
          'profile': {
            'name': name ?? user.displayName ?? 'User',
            'email': user.email,
            'avatar': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'isAnonymous': user.isAnonymous,
          },
          'settings': {
            'theme': 'dark',
            'notifications': true,
            'privacy': 'private',
          },
          'metadata': {
            'totalSessions': 0,
            'lastActive': FieldValue.serverTimestamp(),
          },
        });
      }
    } catch (e) {
      debugPrint('Failed to create user profile: $e');
    }
  }

  /// Update user profile in Firestore
  Future<void> _updateUserProfile(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.update({
        'profile.name': user.displayName,
        'profile.email': user.email,
        'profile.avatar': user.photoURL,
        'profile.isAnonymous': user.isAnonymous,
        'metadata.lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
    }
  }

  /// Delete user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete user profile
      batch.delete(_firestore.collection('users').doc(userId));
      
      // Delete user chat sessions
      final sessions = await _firestore
          .collection('chats')
          .doc(userId)
          .collection('sessions')
          .get();
      
      for (final doc in sessions.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete chat collection document
      batch.delete(_firestore.collection('chats').doc(userId));
      
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to delete user data: $e');
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Failed to get user profile: $e');
      return null;
    }
  }

  /// Update user profile data
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        ...data,
        'metadata.lastActive': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Failed to update user profile: $e');
      return false;
    }
  }
} 