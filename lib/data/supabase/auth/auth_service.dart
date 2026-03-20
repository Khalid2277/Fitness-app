import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps [SupabaseClient.auth] and provides typed helpers for every
/// authentication flow used by AlfaNutrition.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  // ──────────────────────── Session helpers ──────────────────────────────

  /// The current auth session, or `null` if not signed in.
  Session? get currentSession => _client.auth.currentSession;

  /// The currently authenticated user, or `null`.
  User? get currentUser => _client.auth.currentUser;

  /// Whether a user is currently signed in with a valid session.
  bool get isSignedIn => currentSession != null;

  /// Shortcut for the authenticated user's UUID.
  String? get userId => currentUser?.id;

  /// Stream that emits whenever the auth state changes (sign-in, sign-out,
  /// token refresh, password recovery, etc.).
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  // ──────────────────────── Email / password ────────────────────────────

  /// Creates a new account with [email] and [password].
  ///
  /// Optionally stores the user's display [name] in `user_metadata` so the
  /// profile trigger can seed the `profiles` table.
  ///
  /// Returns the [AuthResponse]. If email confirmation is required,
  /// `response.session` will be `null` — caller should show a
  /// "check your email" message.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'display_name': name} : null,
    );
  }

  /// Signs in with [email] and [password].
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ──────────────────────── Password management ─────────────────────────

  /// Sends a password-reset email to [email].
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Updates the signed-in user's password to [newPassword].
  Future<UserResponse> updatePassword(String newPassword) async {
    return _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // ──────────────────────── Apple Sign-In (native) ────────────────────────

  /// Sign in with Apple using the **native iOS sheet** (no browser popup).
  ///
  /// Uses the `sign_in_with_apple` package to get the Apple ID token,
  /// then passes it to Supabase via `signInWithIdToken`.
  ///
  /// Returns the [AuthResponse] with a valid session on success.
  Future<AuthResponse> signInWithApple() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      throw UnsupportedError(
        'Apple Sign-In is only available on Apple platforms.',
      );
    }

    // Generate a random nonce for security
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    // Show the native Apple Sign-In sheet
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In failed: no identity token received.');
    }

    // Exchange the Apple ID token for a Supabase session
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  /// Generates a cryptographically secure random nonce.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  // ──────────────────────── Sign out ────────────────────────────────────

  /// Signs out the current user (local + remote session invalidation).
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ──────────────────────── Token refresh ───────────────────────────────

  /// Manually refreshes the current session token.
  Future<AuthResponse> refreshSession() async {
    return _client.auth.refreshSession();
  }
}
