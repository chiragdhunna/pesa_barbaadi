import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pesa_barbaadi/models/fuel_entry.dart';
import 'package:pesa_barbaadi/models/trip.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:uuid/uuid.dart';

class FuelRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String tripId;
  final String currentUserUid;

  FuelRepository({
    required this.tripId,
    required this.currentUserUid,
  });

  /// Watches entries for the current trip, ordered by date descending.
  Stream<List<FuelEntry>> watchEntries() {
    return _firestore
        .collection(AppStrings.tripsCollection)
        .doc(tripId)
        .collection(AppStrings.entriesCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FuelEntry.fromFirestore(doc)).toList());
  }

  /// Adds a new fuel entry and recomputes the trip balance.
  Future<void> addEntry(FuelEntry entry) async {
    await _firestore
        .collection(AppStrings.tripsCollection)
        .doc(tripId)
        .collection(AppStrings.entriesCollection)
        .add(entry.toFirestore());
    await _recomputeBalance();
  }

  /// Deletes a fuel entry and recomputes the trip balance.
  Future<void> deleteEntry(String entryId) async {
    await _firestore
        .collection(AppStrings.tripsCollection)
        .doc(tripId)
        .collection(AppStrings.entriesCollection)
        .doc(entryId)
        .delete();
    await _recomputeBalance();
  }

  /// Recomputes the 50/50 balance using a Firestore transaction.
  Future<void> _recomputeBalance() async {
    await _firestore.runTransaction((transaction) async {
      final tripRef = _firestore.collection(AppStrings.tripsCollection).doc(tripId);
      final entriesRef = tripRef.collection(AppStrings.entriesCollection);

      // Fetch all entries for this trip
      final entriesSnapshot = await entriesRef.get();
      final entries = entriesSnapshot.docs
          .map((doc) => FuelEntry.fromFirestore(doc))
          .toList();

      if (entries.isEmpty) {
        transaction.update(tripRef, {
          'balance': {
            'owedBy': null,
            'owedTo': null,
            'amount': 0.0,
          }
        });
        return;
      }

      // Compute total spent per member
      final Map<String, double> totalByUid = {};
      double totalSpent = 0.0;

      for (final entry in entries) {
        totalByUid[entry.paidByUid] = (totalByUid[entry.paidByUid] ?? 0.0) + entry.amount;
        totalSpent += entry.amount;
      }

      final fairShare = totalSpent / 2.0;
      
      // We assume there are exactly 2 members in the trip for the 50/50 logic
      // But we find who paid more than the fair share
      String? owedTo;
      String? owedBy;
      double balanceAmount = 0.0;

      final tripDoc = await transaction.get(tripRef);
      final members = Map<String, String>.from(tripDoc.data()?['members'] ?? {});
      final uids = members.keys.toList();

      if (uids.length < 2) {
        // If only one member, balance is 0
        balanceAmount = 0.0;
      } else {
        final uid1 = uids[0];
        final uid2 = uids[1];
        
        final paid1 = totalByUid[uid1] ?? 0.0;
        final paid2 = totalByUid[uid2] ?? 0.0;

        if (paid1 > paid2) {
          owedTo = uid1;
          owedBy = uid2;
          balanceAmount = paid1 - fairShare;
        } else if (paid2 > paid1) {
          owedTo = uid2;
          owedBy = uid1;
          balanceAmount = paid2 - fairShare;
        } else {
          // Exactly equal
          balanceAmount = 0.0;
        }
      }

      transaction.update(tripRef, {
        'balance': {
          'owedBy': owedBy,
          'owedTo': owedTo,
          'amount': balanceAmount.abs(),
        }
      });
    });
  }

  /// Static method to create a new trip document.
  static Future<String> createTrip(String myUid, String myDisplayName) async {
    final firestore = FirebaseFirestore.instance;
    final tripId = const Uuid().v4();
    
    await firestore.collection(AppStrings.tripsCollection).doc(tripId).set({
      'createdAt': FieldValue.serverTimestamp(),
      'members': {
        myUid: myDisplayName,
      },
      'balance': {
        'owedBy': null,
        'owedTo': null,
        'amount': 0.0,
      },
    });
    
    return tripId;
  }

  /// Updates the trip document to include a new member.
  Future<void> joinTrip(String tripId, String myUid, String myDisplayName) async {
    await _firestore.collection(AppStrings.tripsCollection).doc(tripId).update({
      'members.$myUid': myDisplayName,
    });
  }

  /// Watches the trip document for real-time updates.
  Stream<Trip> watchTrip() {
    return _firestore
        .collection(AppStrings.tripsCollection)
        .doc(tripId)
        .snapshots()
        .map((doc) => Trip.fromFirestore(doc));
  }
}
