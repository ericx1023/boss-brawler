import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Initialize GoogleSignIn with explicit clientId from Firebase config
    _googleSignIn = GoogleSignIn(
      signInOption: SignInOption.standard,
      // Use the CLIENT_ID from your GoogleService-Info.plist
      clientId: '750386372057-03li2kvdjlgmeop0kigb8gd329sfsbf5.apps.googleusercontent.com',
    );
    
    // Verify Google Sign-In is properly configured
    debugPrint('🔧 AuthService initialized');
    debugPrint('🔧 GoogleSignIn clientId: ${_googleSignIn.clientId}');
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
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
      debugPrint('🚀 Starting Google Sign In...');
      debugPrint('🔧 GoogleSignIn configuration: ${_googleSignIn.clientId}');
      
      // First try to sign in silently to check if user is already authenticated
      debugPrint('📱 Attempting silent sign in first...');
      try {
        final silentUser = await _googleSignIn.signInSilently();
        if (silentUser != null) {
          debugPrint('✅ Silent sign in successful: ${silentUser.email}');
          // Continue with Firebase authentication
          final GoogleSignInAuthentication googleAuth = await silentUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          final result = await _auth.signInWithCredential(credential);
          await _createUserProfile(result.user!);
          return result;
        }
      } catch (e) {
        debugPrint('📱 Silent sign in failed: $e');
      }
      
      debugPrint('📱 Calling _googleSignIn.signIn()...');
      debugPrint('📱 Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      debugPrint('📱 Is running on device: ${!kIsWeb && (Platform.isIOS || Platform.isAndroid)}');
      
      // Check if already signed in
      final currentGoogleUser = _googleSignIn.currentUser;
      debugPrint('📱 Current Google user: ${currentGoogleUser?.email ?? "none"}');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ Google Sign In timed out after 10 seconds');
          debugPrint('❌ This might be a simulator issue - try testing on a physical device');
          return null;
        },
      );
      debugPrint('📱 _googleSignIn.signIn() completed');
      debugPrint('📱 Returned googleUser: ${googleUser?.email ?? "null"}');
      
      if (googleUser == null) {
        debugPrint('❌ Google Sign In returned null - checking if user cancelled or error occurred');
        
        // Try to get more details about why it failed
        try {
          await _googleSignIn.signInSilently();
          debugPrint('📱 Silent sign in attempt completed');
        } catch (e) {
          debugPrint('📱 Silent sign in failed: $e');
        }
        
        return null; // User cancelled or error occurred
      }

      debugPrint('✅ Google user obtained: ${googleUser.email}');
      
      debugPrint('🔑 Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('🔑 Authentication tokens obtained');
      
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
      
      // Create user profile with timeout to prevent infinite loading
      try {
        await _createUserProfile(result.user!).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⚠️ User profile creation timed out, but login succeeded');
          },
        );
      } catch (e) {
        debugPrint('⚠️ User profile creation failed: $e');
        debugPrint('✅ Login still successful, continuing...');
      }
      
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
      debugPrint('🔥 Starting user profile creation for ${user.email}');
      
      final userDoc = _firestore.collection('users').doc(user.uid);
      debugPrint('🔥 Checking if user document exists...');
      
      final exists = await userDoc.get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('🔥 Firestore get() timed out');
          throw Exception('Firestore operation timed out');
        },
      );
      
      debugPrint('🔥 User document exists: ${exists.exists}');
      
      if (!exists.exists) {
        debugPrint('🔥 Creating new user document...');
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
        }).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('🔥 Firestore set() timed out');
            throw Exception('Firestore set operation timed out');
          },
        );
        debugPrint('🔥 User profile created successfully');
      } else {
        debugPrint('🔥 User profile already exists, skipping creation');
      }
    } catch (e) {
      debugPrint('Failed to create user profile: $e');
      rethrow;
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