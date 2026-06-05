import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/services/export_service.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:pesa_barbaadi/utils/formatters.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  final ExportService _exportService = ExportService();

  Future<void> _handleExport(String type) async {
    final entriesAsync = ref.read(entriesProvider);
    final user = ref.read(currentUserProvider);
    final tripAsync = ref.read(tripProvider);

    if (user == null || tripAsync.value == null || entriesAsync.value == null) return;

    final entries = entriesAsync.value!;
    final trip = tripAsync.value!;
    
    final myUid = user.uid;
    final myName = trip.members[myUid] ?? 'User';
    final friendUid = trip.members.keys.firstWhere((id) => id != myUid, orElse: () => '');
    final friendName = trip.members[friendUid] ?? 'Friend';

    try {
      switch (type) {
        case 'excel':
          await _exportService.exportToExcel(entries, myName, friendName, _dateRange);
          break;
        case 'pdf':
          await _exportService.exportToPdf(entries, myName, friendName, _dateRange);
          break;
        case 'csv':
          await _exportService.exportToCsv(entries, _dateRange);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Report'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  initialDateRange: _dateRange,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          surface: AppColors.surface,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) setState(() => _dateRange = range);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.textMuted),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                    const SizedBox(width: 16),
                    Text(
                      '${AppFormatters.formatDate(_dateRange.start)} - ${AppFormatters.formatDate(_dateRange.end)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            const Text(
              'Choose Format',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _ExportOptionCard(
              title: 'Microsoft Excel (.xlsx)',
              subtitle: 'Best for spreadsheet analysis',
              icon: Icons.table_chart,
              iconColor: Colors.green,
              onTap: () => _handleExport('excel'),
            ),
            const SizedBox(height: 16),
            _ExportOptionCard(
              title: 'PDF Document (.pdf)',
              subtitle: 'Best for sharing and printing',
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red,
              onTap: () => _handleExport('pdf'),
            ),
            const SizedBox(height: 16),
            _ExportOptionCard(
              title: 'Comma Separated (.csv)',
              subtitle: 'Best for data import',
              icon: Icons.description,
              iconColor: Colors.blue,
              onTap: () => _handleExport('csv'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
