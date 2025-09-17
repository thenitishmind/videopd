import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('General Error: $e');
      }
      throw 'An unexpected error occurred. Please try again.';
    }
  }



  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      throw 'Error signing out. Please try again.';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return '❌ No user account found with this email address.\n\n💡 Please check your email address or contact your administrator to create an account.';
      case 'wrong-password':
        return '❌ Incorrect password.\n\n💡 Please check your password and try again.';
      case 'invalid-email':
        return '❌ Invalid email address format.\n\n💡 Please enter a valid email address.';
      case 'user-disabled':
        return '❌ This user account has been disabled.\n\n💡 Please contact your administrator.';
      case 'too-many-requests':
        return '❌ Too many failed login attempts.\n\n💡 Please wait a few minutes and try again.';
      case 'invalid-credential':
        return '❌ Invalid email or password.\n\n💡 Please check your credentials and try again.\n\n📧 If you need an account, contact your administrator.';
      case 'network-request-failed':
        return '❌ Network connection error.\n\n💡 Please check your internet connection and try again.';
      case 'app-not-authorized':
        return '❌ App authentication error.\n\n💡 Please contact technical support.';
      case 'operation-not-allowed':
        return '❌ Email/password login is not enabled.\n\n💡 Please contact your administrator.';
      case 'quota-exceeded':
        return '❌ Too many requests.\n\n💡 Please try again later.';
      case 'email-already-in-use':
        return '❌ An account with this email already exists.\n\n💡 Try logging in instead.';
      case 'weak-password':
        return '❌ Password is too weak.\n\n💡 Please choose a stronger password.';
      case 'account-exists-with-different-credential':
        return '❌ Account exists with different login method.\n\n💡 Try logging in with your original method.';
      default:
        return '❌ Authentication failed: ${e.message ?? 'Unknown error'}\n\n💡 Please check your credentials and try again, or contact support if the problem persists.';
    }
  }

  bool get isLoggedIn => currentUser != null;
}