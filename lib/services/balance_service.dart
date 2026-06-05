import 'package:pesa_barbaadi/models/fuel_entry.dart';

class BalanceSummary {
  final double totalSpent;
  final double youPaid;
  final double friendPaid;
  final double fairShare;
  final double balance; // positive = friend owes you; negative = you owe friend
  final bool isSettled;
  final String? owesDirection; // "friend_owes_you" | "you_owe_friend" | "settled"

  const BalanceSummary({
    required this.totalSpent,
    required this.youPaid,
    required this.friendPaid,
    required this.fairShare,
    required this.balance,
    required this.isSettled,
    this.owesDirection,
  });
}

class BalanceService {
  /// Computes the 50/50 balance summary from a list of fuel entries.
  static BalanceSummary compute(List<FuelEntry> entries, String myUid) {
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
    final isSettled = balance.abs() < 1.0; // Settled if difference is less than 1 rupee

    String? direction;
    if (isSettled) {
      direction = "settled";
    } else {
      direction = balance > 0 ? "friend_owes_you" : "you_owe_friend";
    }

    return BalanceSummary(
      totalSpent: totalSpent,
      youPaid: youPaid,
      friendPaid: friendPaid,
      fairShare: fairShare,
      balance: balance,
      isSettled: isSettled,
      owesDirection: direction,
    );
  }
}
