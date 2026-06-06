import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/services/export_service.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:pesa_barbaadi/models/fuel_entry.dart';

enum DateRangeOption { thisMonth, last3Months, allTime }

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateRangeOption _selectedOption = DateRangeOption.thisMonth;
  bool _isExportingExcel = false;
  bool _isExportingPdf = false;
  bool _isExportingCsv = false;

  final ExportService _exportService = ExportService();

  DateTimeRange? get _currentRange {
    final now = DateTime.now();
    switch (_selectedOption) {
      case DateRangeOption.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case DateRangeOption.last3Months:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
      case DateRangeOption.allTime:
        return null;
    }
  }

  Future<void> _handleExport(String type) async {
    final entriesAsync = ref.read(entriesProvider);
    final user = ref.read(currentUserProvider);
    final tripAsync = ref.read(tripProvider);

    if (user == null || tripAsync.value == null || entriesAsync.value == null) {
      return;
    }

    final entries = entriesAsync.value!;
    final trip = tripAsync.value!;

    final myUid = user.uid;
    final myName = trip.members[myUid] ?? 'User';
    final friendUid =
        trip.members.keys.firstWhere((id) => id != myUid, orElse: () => '');
    final friendName = trip.members[friendUid] ?? 'Friend';

    setState(() {
      if (type == 'excel') _isExportingExcel = true;
      if (type == 'pdf') _isExportingPdf = true;
      if (type == 'csv') _isExportingCsv = true;
    });

    try {
      switch (type) {
        case 'excel':
          await _exportService.exportToExcel(
              entries, myName, friendName, _currentRange);
          break;
        case 'pdf':
          await _exportService.exportToPdf(
              entries, myName, friendName, _currentRange);
          break;
        case 'csv':
          await _exportService.exportToCsv(entries, _currentRange);
          break;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.toUpperCase()} exported successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (type == 'excel') _isExportingExcel = false;
          if (type == 'pdf') _isExportingPdf = false;
          if (type == 'csv') _isExportingCsv = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesProvider);
    final user = ref.watch(currentUserProvider);
    final tripAsync = ref.watch(tripProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📊 Export Report'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.query_stats,
                        size: 64, color: AppColors.textMuted),
                    SizedBox(height: 16),
                    Text(
                      'No entries available to export.',
                      style: TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Range',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChoiceChip(DateRangeOption.thisMonth, 'This Month'),
                    _buildChoiceChip(
                        DateRangeOption.last3Months, 'Last 3 Months'),
                    _buildChoiceChip(DateRangeOption.allTime, 'All Time'),
                  ],
                ),
                const SizedBox(height: 32),
                if (user != null && tripAsync.value != null)
                  _SummaryPreviewCard(
                    entries: entries,
                    range: _currentRange,
                    myUid: user.uid,
                    friendName: tripAsync.value!.members.entries
                        .firstWhere((e) => e.key != user.uid,
                            orElse: () => const MapEntry('', 'Friend'))
                        .value,
                  ),
                const SizedBox(height: 48),
                const Text(
                  'Choose Format',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _ExportOptionCard(
                  title: 'Microsoft Excel (.xlsx)',
                  subtitle: 'Best for spreadsheet analysis',
                  icon: Icons.table_chart,
                  iconColor: Colors.green,
                  isLoading: _isExportingExcel,
                  onTap: () => _handleExport('excel'),
                ),
                const SizedBox(height: 16),
                _ExportOptionCard(
                  title: 'PDF Document (.pdf)',
                  subtitle: 'Best for sharing and printing',
                  icon: Icons.picture_as_pdf,
                  iconColor: Colors.red,
                  isLoading: _isExportingPdf,
                  onTap: () => _handleExport('pdf'),
                ),
                const SizedBox(height: 16),
                _ExportOptionCard(
                  title: 'Comma Separated (.csv)',
                  subtitle: 'Best for data import',
                  icon: Icons.description,
                  iconColor: Colors.blue,
                  isLoading: _isExportingCsv,
                  onTap: () => _handleExport('csv'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildChoiceChip(DateRangeOption option, String label) {
    final isSelected = _selectedOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedOption = option);
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _SummaryPreviewCard extends StatelessWidget {
  final List<FuelEntry> entries;
  final DateTimeRange? range;
  final String myUid;
  final String friendName;

  const _SummaryPreviewCard({
    required this.entries,
    required this.range,
    required this.myUid,
    required this.friendName,
  });

  @override
  Widget build(BuildContext context) {
    final r = range;
    final filtered = entries.where((e) {
      if (r == null) return true;
      // Inclusive filtering: start of day to end of day
      final start = DateTime(r.start.year, r.start.month, r.start.day);
      final end = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59);
      return (e.date.isAfter(start) || e.date.isAtSameMomentAs(start)) &&
          (e.date.isBefore(end) || e.date.isAtSameMomentAs(end));
    }).toList();

    double myTotal = 0;
    double friendTotal = 0;

    for (var entry in filtered) {
      if (entry.paidByUid == myUid) {
        myTotal += entry.amount;
      } else {
        friendTotal += entry.amount;
      }
    }

    final total = myTotal + friendTotal;
    final fairShare = total / 2;
    final balance = myTotal - fairShare;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Summary Preview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${filtered.length} entries',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 32, color: AppColors.textMuted),
          _SummaryRow(label: 'Total Spent', value: total, isBold: true),
          const SizedBox(height: 12),
          _SummaryRow(
              label: 'You Paid', value: myTotal, color: AppColors.success),
          const SizedBox(height: 8),
          _SummaryRow(
              label: '$friendName Paid',
              value: friendTotal,
              color: AppColors.primary),
          const Divider(height: 32, color: AppColors.textMuted),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                balance > 0
                    ? '$friendName owes you ₹${balance.abs().toStringAsFixed(2)}'
                    : balance < 0
                        ? 'You owe $friendName ₹${balance.abs().toStringAsFixed(2)}'
                        : 'Settled',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
