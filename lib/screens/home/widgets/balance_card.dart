import 'package:flutter/material.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:pesa_barbaadi/utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance; // positive = friend owes you, negative = you owe friend
  final bool isSettled;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.isSettled,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    String message;
    IconData icon;

    if (isSettled) {
      cardColor = AppColors.success.withOpacity(0.1);
      message = AppStrings.settled;
      icon = Icons.check_circle_outline;
    } else if (balance > 0) {
      cardColor = AppColors.success.withOpacity(0.1);
      message = '${AppStrings.friendOwes} ${AppFormatters.formatCurrency(balance.abs())}';
      icon = Icons.arrow_upward;
    } else {
      cardColor = AppColors.danger.withOpacity(0.1);
      message = '${AppStrings.youOwe} ${AppFormatters.formatCurrency(balance.abs())}';
      icon = Icons.arrow_downward;
    }

    final textColor = balance > 0 || isSettled ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (balance > 0 && !isSettled)
              TextButton(
                onPressed: () {
                  // Placeholder for "Remind" button
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Remind'),
              ),
          ],
        ),
      ),
    );
  }
}
