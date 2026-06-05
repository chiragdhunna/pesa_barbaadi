import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/screens/history/widgets/monthly_bar_chart.dart';
import 'package:pesa_barbaadi/screens/home/widgets/entry_list_tile.dart';
import 'package:pesa_barbaadi/utils/constants.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No entries yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spending Trends',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      MonthlyBarChart(
                        entries: entries,
                        myUid: user?.uid ?? '',
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'All Entries',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = entries[index];
                    return Column(
                      children: [
                        EntryListTile(entry: entry),
                        if (index < entries.length - 1)
                          const Divider(
                            height: 1,
                            color: AppColors.elevatedSurface,
                            indent: 72,
                          ),
                      ],
                    );
                  },
                  childCount: entries.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
