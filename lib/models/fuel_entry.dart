import 'package:cloud_firestore/cloud_firestore.dart';

class FuelEntry {
  final String id;
  final String paidByUid;
  final String paidByName;
  final double amount;
  final DateTime date;
  final String type; // "full" or "partial"
  final String? note;
  final DateTime createdAt;

  const FuelEntry({
    required this.id,
    required this.paidByUid,
    required this.paidByName,
    required this.amount,
    required this.date,
    required this.type,
    this.note,
    required this.createdAt,
  });

  factory FuelEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FuelEntry(
      id: doc.id,
      paidByUid: data['paidByUid'] ?? '',
      paidByName: data['paidByName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'full',
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'paidByUid': paidByUid,
      'paidByName': paidByName,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FuelEntry copyWith({
    String? id,
    String? paidByUid,
    String? paidByName,
    double? amount,
    DateTime? date,
    String? type,
    String? note,
    DateTime? createdAt,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      paidByUid: paidByUid ?? this.paidByUid,
      paidByName: paidByName ?? this.paidByName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
