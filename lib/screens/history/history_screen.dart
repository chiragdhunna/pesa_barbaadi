import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pesa_barbaadi/models/fuel_entry.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/screens/history/widgets/monthly_bar_chart.dart';
import 'package:pesa_barbaadi/screens/home/widgets/entry_list_tile.dart';
import 'package:pesa_barbaadi/utils/constants.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _selectedPayerUid; // null = All, else = UID
  String? _selectedMonth; // null = All, else = "MMMM yyyy"

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final user = ref.watch(currentUserProvider);
    final tripAsync = ref.watch(tripProvider);

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

          final trip = tripAsync.value;
          final myUid = user?.uid ?? '';
          final friendUid = trip?.members.keys
                  .firstWhere((id) => id != myUid, orElse: () => '') ??
              '';
          final friendName = trip?.members[friendUid] ?? 'Friend';

          // 1. Get unique months for filter pills
          final Set<String> months = {};
          for (var entry in entries) {
            months.add(DateFormat('MMMM yyyy').format(entry.date));
          }
          final sortedMonths = months.toList()
            ..sort((a, b) {
              final dateA = DateFormat('MMMM yyyy').parse(a);
              final dateB = DateFormat('MMMM yyyy').parse(b);
              return dateB.compareTo(dateA);
            });

          // 2. Filter entries
          var filteredEntries = entries;
          if (_selectedPayerUid != null) {
            filteredEntries = filteredEntries
                .where((e) => e.paidByUid == _selectedPayerUid)
                .toList();
          }
          if (_selectedMonth != null) {
            filteredEntries = filteredEntries
                .where((e) =>
                    DateFormat('MMMM yyyy').format(e.date) == _selectedMonth)
                .toList();
          }

          // 3. Group filtered entries by month
          final Map<String, List<FuelEntry>> groupedEntries = {};
          for (var entry in filteredEntries) {
            final month = DateFormat('MMMM yyyy').format(entry.date);
            groupedEntries.putIfAbsent(month, () => []).add(entry);
          }
          final sortedGroupedMonths = groupedEntries.keys.toList()
            ..sort((a, b) {
              final dateA = DateFormat('MMMM yyyy').parse(a);
              final dateB = DateFormat('MMMM yyyy').parse(b);
              return dateB.compareTo(dateA);
            });

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
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
                            myUid: myUid,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            isSelected: _selectedPayerUid == null,
                            onTap: () =>
                                setState(() => _selectedPayerUid = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'You',
                            isSelected: _selectedPayerUid == myUid,
                            onTap: () =>
                                setState(() => _selectedPayerUid = myUid),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: friendName,
                            isSelected: _selectedPayerUid == friendUid,
                            onTap: () =>
                                setState(() => _selectedPayerUid = friendUid),
                          ),
                          const SizedBox(width: 16),
                          Container(
                              width: 1,
                              height: 24,
                              color: AppColors.elevatedSurface),
                          const SizedBox(width: 16),
                          _FilterChip(
                            label: 'All Months',
                            isSelected: _selectedMonth == null,
                            onTap: () => setState(() => _selectedMonth = null),
                          ),
                          ...sortedMonths.map((month) => Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: _FilterChip(
                                  label: month,
                                  isSelected: _selectedMonth == month,
                                  onTap: () =>
                                      setState(() => _selectedMonth = month),
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              if (filteredEntries.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No entries match these filters.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...sortedGroupedMonths.map((month) => SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            child: Text(
                              month.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = groupedEntries[month]![index];
                              return Dismissible(
                                key: Key(entry.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) =>
                                    _showDeleteDialog(context, ref, entry),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  color: AppColors.danger,
                                  child: const Icon(Icons.delete_outline,
                                      color: Colors.white),
                                ),
                                child: EntryListTile(entry: entry),
                              );
                            },
                            childCount: groupedEntries[month]!.length,
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    )),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(
      BuildContext context, WidgetRef ref, FuelEntry entry) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Entry',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to delete this fuel entry?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(fuelRepositoryProvider)?.deleteEntry(entry.id);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry deleted')),
              );
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textMuted.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
