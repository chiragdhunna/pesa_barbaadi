import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pesa_barbaadi/repositories/auth_repository.dart';

/// Provider for the AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// StreamProvider that watches the user's authentication state.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provider for the currently authenticated user.
final currentUserProvider = Provider<User?>((ref) {
  // We watch authStateProvider to ensure this provider updates when the state changes.
  // Using .value to get the current value of the stream.
  return ref.watch(authStateProvider).value;
});
