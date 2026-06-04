import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F1117);
  static const Color surface = Color(0xFF161B28);
  static const Color elevatedSurface = Color(0xFF1E2130);
  static const Color primary = Color(0xFF5B7FFF);
  static const Color success = Color(0xFF3ECF8E);
  static const Color danger = Color(0xFFFF6B6B);

  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF888BA0);
  static const Color textMuted = Color(0xFF555870);

  // Success is "you paid", Primary is "friend paid"
  static const Color youPaid = success;
  static const Color friendPaid = primary;
}

class AppStrings {
  static const String appName = 'Pesa Barbaadi';
  static const String welcomeMessage = 'Split petrol costs with a friend';

  // Firestore Collection Names
  static const String tripsCollection = 'trips';
  static const String entriesCollection = 'entries';

  // UI Labels
  static const String totalSpent = 'Total Spent';
  static const String youPaidLabel = 'You Paid';
  static const String friendPaidLabel = 'Friend Paid';
  static const String fairShare = 'Fair Share';
  static const String balance = 'Balance';
  static const String youOwe = 'You owe';
  static const String friendOwes = 'Friend owes';
  static const String settled = 'Settled';

  // Entry Types
  static const String typeFull = 'full';
  static const String typePartial = 'partial';
}
