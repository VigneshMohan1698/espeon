import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '90269352050-9g1q4rqde11bqooqk81nkqdker3b4100.apps.googleusercontent.com',
  );

  AuthStatus status = AuthStatus.idle;
  String? errorMessage;
  User? get currentUser => _auth.currentUser;

  // ── Google Sign-In ──────────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    _setLoading();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setIdle(); // user cancelled
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      _setSuccess();
    } catch (e) {
      _setError('Google sign-in failed. Please try again.');
    }
  }

  // ── Apple Sign-In ───────────────────────────────────────────────
  Future<void> signInWithApple() async {
    _setLoading();
    try {
      final appleProvider = AppleAuthProvider();
      await _auth.signInWithProvider(appleProvider);
      _setSuccess();
    } catch (e) {
      _setError('Apple sign-in failed. Please try again.');
    }
  }

  // ── Email & Password ────────────────────────────────────────────
  Future<void> signInWithEmail(String email, String password) async {
    _setLoading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setSuccess();
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-in FirebaseAuthException: ${e.code} — ${e.message}');
      _setError(_friendlyError(e.code));
    } catch (e) {
      debugPrint('Email sign-in unexpected error: $e');
      _setError('Something went wrong: $e');
    }
  }

  Future<void> createAccountWithEmail(String email, String password) async {
    _setLoading();
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      _setSuccess();
    } on FirebaseAuthException catch (e) {
      debugPrint('Email sign-up FirebaseAuthException: ${e.code} — ${e.message}');
      _setError(_friendlyError(e.code));
    } catch (e) {
      debugPrint('Email sign-up unexpected error: $e');
      _setError('Something went wrong: $e');
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _setIdle();
  }

  // ── Helpers ─────────────────────────────────────────────────────
  void _setLoading() {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
  }

  void _setSuccess() {
    status = AuthStatus.success;
    notifyListeners();
  }

  void _setIdle() {
    status = AuthStatus.idle;
    notifyListeners();
  }

  void _setError(String message) {
    status = AuthStatus.error;
    errorMessage = message;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
