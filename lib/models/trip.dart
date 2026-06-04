import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final Map<String, String> members; // uid -> displayName
  final String? owedByUid; // who owes money
  final String? owedToUid; // who is owed
  final double balanceAmount; // always positive, 0.0 if settled

  const Trip({
    required this.id,
    required this.members,
    this.owedByUid,
    this.owedToUid,
    required this.balanceAmount,
  });

  bool get isSettled => balanceAmount == 0.0;

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final balance = data['balance'] as Map<String, dynamic>? ?? {};
    
    return Trip(
      id: doc.id,
      members: Map<String, String>.from(data['members'] ?? {}),
      owedByUid: balance['owedBy'],
      owedToUid: balance['owedTo'],
      balanceAmount: (balance['amount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'members': members,
      'balance': {
        'owedBy': owedByUid,
        'owedTo': owedToUid,
        'amount': balanceAmount,
      },
    };
  }

  Trip copyWith({
    String? id,
    Map<String, String>? members,
    String? owedByUid,
    String? owedToUid,
    double? balanceAmount,
  }) {
    return Trip(
      id: id ?? this.id,
      members: members ?? this.members,
      owedByUid: owedByUid ?? this.owedByUid,
      owedToUid: owedToUid ?? this.owedToUid,
      balanceAmount: balanceAmount ?? this.balanceAmount,
    );
  }
}
