import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pesa_barbaadi/models/fuel_entry.dart';
import 'package:pesa_barbaadi/models/trip.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/repositories/fuel_repository.dart';

/// Provider for the current trip ID.
final tripIdProvider = StateProvider<String?>((ref) => null);

/// Provider for the FuelRepository.
/// Returns null if tripId or user is not available.
final fuelRepositoryProvider = Provider<FuelRepository?>((ref) {
  final tripId = ref.watch(tripIdProvider);
  final user = ref.watch(currentUserProvider);

  if (tripId == null || user == null) return null;

  return FuelRepository(
    tripId: tripId,
    currentUserUid: user.uid,
  );
});

/// StreamProvider for fuel entries of the current trip.
final entriesProvider = StreamProvider<List<FuelEntry>>((ref) {
  final repository = ref.watch(fuelRepositoryProvider);
  if (repository == null) return Stream.value([]);
  return repository.watchEntries();
});

/// StreamProvider for the current trip details.
final tripProvider = StreamProvider<Trip?>((ref) {
  final repository = ref.watch(fuelRepositoryProvider);
  if (repository == null) return Stream.value(null);
  return repository.watchTrip();
});

/// Provider that computes the balance summary from fuel entries.
final balanceSummaryProvider = Provider<Map<String, double>>((ref) {
  final entriesAsync = ref.watch(entriesProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null || entriesAsync.value == null || entriesAsync.value!.isEmpty) {
    return {
      'totalSpent': 0.0,
      'youPaid': 0.0,
      'friendPaid': 0.0,
      'fairShare': 0.0,
      'balance': 0.0,
    };
  }

  final entries = entriesAsync.value!;
  final myUid = user.uid;

  double totalSpent = 0.0;
  double youPaid = 0.0;
  double friendPaid = 0.0;

  for (final entry in entries) {
    totalSpent += entry.amount;
    if (entry.paidByUid == myUid) {
      youPaid += entry.amount;
    } else {
      friendPaid += entry.amount;
    }
  }

  final fairShare = totalSpent / 2.0;
  final balance = youPaid - fairShare; // Positive means friend owes you

  return {
    'totalSpent': totalSpent,
    'youPaid': youPaid,
    'friendPaid': friendPaid,
    'fairShare': fairShare,
    'balance': balance,
  };
});
