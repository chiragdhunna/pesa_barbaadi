import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pesa_barbaadi/models/fuel_entry.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';
import 'package:pesa_barbaadi/utils/constants.dart';
import 'package:pesa_barbaadi/utils/formatters.dart';
import 'package:uuid/uuid.dart';

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  late String _selectedPayer;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = AppStrings.typeFull;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedPayer = ref.read(currentUserProvider)?.uid ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final tripAsync = ref.read(tripProvider);
    final repository = ref.read(fuelRepositoryProvider);

    if (user == null || tripAsync.value == null || repository == null) return;

    final trip = tripAsync.value!;
    final paidByName = trip.members[_selectedPayer] ?? 'User';

    final entry = FuelEntry(
      id: const Uuid().v4(),
      paidByUid: _selectedPayer,
      paidByName: paidByName,
      amount: double.parse(_amountController.text),
      date: _selectedDate,
      type: _selectedType,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await repository.addEntry(entry);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry added')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final tripAsync = ref.watch(tripProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Log fuel entry'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          final myUid = user?.uid ?? '';
          final friendUid = trip.members.keys
              .firstWhere((id) => id != myUid, orElse: () => '');
          final friendName = trip.members[friendUid] ?? 'Friend';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Who paid?',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PayerButton(
                          label: 'You',
                          isSelected: _selectedPayer == myUid,
                          onTap: () => setState(() => _selectedPayer = myUid),
                          selectedColor: AppColors.primary,
                          selectedBgColor:
                              AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PayerButton(
                          label: friendName,
                          isSelected: _selectedPayer == friendUid,
                          onTap: () =>
                              setState(() => _selectedPayer = friendUid),
                          selectedColor: AppColors.success,
                          selectedBgColor:
                              AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Amount (₹)',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textMuted)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  const Text('Date',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: AppColors.textMuted)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppFormatters.formatDate(_selectedDate),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                          const Spacer(),
                          const Icon(Icons.calendar_today,
                              color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Fill type',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Full tank'),
                        selected: _selectedType == AppStrings.typeFull,
                        onSelected: (selected) =>
                            setState(() => _selectedType = AppStrings.typeFull),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: _selectedType == AppStrings.typeFull
                                ? Colors.white
                                : AppColors.textSecondary),
                        backgroundColor: AppColors.surface,
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Partial'),
                        selected: _selectedType == AppStrings.typePartial,
                        onSelected: (selected) => setState(
                            () => _selectedType = AppStrings.typePartial),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                            color: _selectedType == AppStrings.typePartial
                                ? Colors.white
                                : AppColors.textSecondary),
                        backgroundColor: AppColors.surface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Note (optional)',
                      style: TextStyle(color: AppColors.textSecondary)),
                  TextFormField(
                    controller: _noteController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. highway trip',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textMuted)),
                      focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save entry',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              'Error: $error',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }
}

class _PayerButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedBgColor;

  const _PayerButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.selectedBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: isSelected ? selectedBgColor : Colors.transparent,
        side:
            BorderSide(color: isSelected ? selectedColor : AppColors.textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? selectedColor : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
