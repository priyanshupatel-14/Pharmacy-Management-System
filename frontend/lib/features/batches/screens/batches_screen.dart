import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/ui_states.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/batch_provider.dart';
import '../models/medicine_batch.dart';
import 'batch_form_dialog.dart';

class BatchesScreen extends StatefulWidget {
  const BatchesScreen({super.key});

  @override
  State<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends State<BatchesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BatchProvider>();
      provider.fetchMedicines();
      provider.fetchBatches();
    });
  }

  void _showFormDialog([MedicineBatch? batch]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BatchFormDialog(batch: batch),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(batch == null ? 'Batch added successfully' : 'Batch updated successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(MedicineBatch batch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete batch ${batch.batchNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await context.read<BatchProvider>().deleteBatch(batch.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Batch deleted successfully'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Batch Management',
              subtitle: 'Track medicine quantities and monitor expiry dates',
              action: FilledButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Batch'),
              ),
            ),
            
            // Toolbar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.filter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Batches')),
                        DropdownMenuItem(value: 'expired', child: Text('Expired Only')),
                        DropdownMenuItem(value: 'expiring_soon', child: Text('Expiring Soon (30d)')),
                      ],
                      onChanged: (val) {
                        if (val != null) provider.setFilter(val);
                      },
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => provider.fetchBatches(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: provider.isLoading
                  ? const LoadingState(message: 'Loading batches...')
                  : provider.errorMessage != null
                      ? ErrorState(
                          message: provider.errorMessage!,
                          onRetry: () => provider.fetchBatches(),
                        )
                      : provider.batches.isEmpty
                          ? const EmptyState(
                              title: 'No batches found',
                              message: 'Adjust your filters or add a new batch.',
                              icon: Icons.category_outlined,
                            )
                          : DataTableCard(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('MEDICINE')),
                                  DataColumn(label: Text('BATCH NO')),
                                  DataColumn(label: Text('EXPIRY DATE')),
                                  DataColumn(label: Text('QUANTITY', textAlign: TextAlign.right)),
                                  DataColumn(label: Text('COST', textAlign: TextAlign.right)),
                                  DataColumn(label: Text('STATUS')),
                                  DataColumn(label: Text('ACTIONS', textAlign: TextAlign.right)),
                                ],
                                rows: provider.batches.map((batch) {
                                  final expired = batch.isExpired;
                                  final soon = batch.isExpiringSoon;

                                  BadgeStatus badgeStatus = BadgeStatus.success;
                                  String statusText = 'Healthy';
                                  
                                  if (expired) {
                                    badgeStatus = BadgeStatus.error;
                                    statusText = 'Expired';
                                  } else if (soon) {
                                    badgeStatus = BadgeStatus.warning;
                                    statusText = 'Expiring Soon';
                                  }

                                  return DataRow(
                                    cells: [
                                      DataCell(Text('#${batch.id}', style: const TextStyle(color: Colors.grey))),
                                      DataCell(Text(batch.medicineName ?? 'ID: ${batch.medicineId}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(batch.batchNumber)),
                                      DataCell(Text(batch.expiryDate)),
                                      DataCell(
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          child: Text(batch.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          child: Text(CurrencyFormatter.format(batch.purchasePrice)),
                                        ),
                                      ),
                                      DataCell(StatusBadge(label: statusText, status: badgeStatus)),
                                      DataCell(
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 18),
                                              tooltip: 'Edit',
                                              onPressed: () => _showFormDialog(batch),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                              tooltip: 'Delete',
                                              onPressed: () => _confirmDelete(batch),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
