import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesa_barbaadi/models/fuel_entry.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:pesa_barbaadi/utils/formatters.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<FuelEntry> entries;
  final String myUid;

  const MonthlyBarChart({
    super.key,
    required this.entries,
    required this.myUid,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Process data for the last 6 months
    final now = DateTime.now();
    final List<DateTime> lastSixMonths = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    final Map<String, Map<String, double>> chartData = {};
    for (var monthDate in lastSixMonths) {
      final key = DateFormat('MMM').format(monthDate);
      chartData[key] = {'me': 0.0, 'friend': 0.0};
    }

    for (var entry in entries) {
      final monthKey = DateFormat('MMM').format(entry.date);
      if (chartData.containsKey(monthKey)) {
        if (entry.paidByUid == myUid) {
          chartData[monthKey]!['me'] =
              (chartData[monthKey]!['me'] ?? 0.0) + entry.amount;
        } else {
          chartData[monthKey]!['friend'] =
              (chartData[monthKey]!['friend'] ?? 0.0) + entry.amount;
        }
      }
    }

    double maxVal = 0;
    chartData.forEach((_, data) {
      if (data['me']! > maxVal) {
        maxVal = data['me']!;
      }
      if (data['friend']! > maxVal) {
        maxVal = data['friend']!;
      }
    });
    // Add 20% buffer to the top
    maxVal = maxVal == 0 ? 1000 : maxVal * 1.2;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surface,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      AppFormatters.formatCurrency(rod.toY),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= lastSixMonths.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('MMM').format(lastSixMonths[index]),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(lastSixMonths.length, (i) {
                final monthKey = DateFormat('MMM').format(lastSixMonths[i]);
                final data = chartData[monthKey]!;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data['me']!,
                      color: AppColors.primary,
                      width: 12,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: data['friend']!,
                      color: AppColors.success,
                      width: 12,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppColors.primary, label: 'You'),
            SizedBox(width: 24),
            _LegendItem(color: AppColors.success, label: 'Friend'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
