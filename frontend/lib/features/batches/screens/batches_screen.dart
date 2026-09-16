import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
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
          backgroundColor: Colors.green,
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await context.read<BatchProvider>().deleteBatch(batch.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch deleted successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BatchProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Batch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Batch Management',
              subtitle: 'Manage medicine batches, track quantities, and monitor expiry dates.',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: provider.filter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Batches')),
                      DropdownMenuItem(value: 'expired', child: Text('Expired')),
                      DropdownMenuItem(value: 'expiring_soon', child: Text('Expiring Soon (30d)')),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.setFilter(val);
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh List',
                    onPressed: () => provider.fetchBatches(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.errorMessage != null
                      ? Center(
                          child: Text(
                            provider.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        )
                      : provider.batches.isEmpty
                          ? const Center(child: Text('No batches found.'))
                          : Card(
                              elevation: 2,
                              child: ListView(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('Medicine')),
                                        DataColumn(label: Text('Batch No')),
                                        DataColumn(label: Text('Expiry Date')),
                                        DataColumn(label: Text('Quantity')),
                                        DataColumn(label: Text('Cost (₹)')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: provider.batches.map((batch) {
                                        final expired = batch.isExpired;
                                        final soon = batch.isExpiringSoon;

                                        Color statusColor = Colors.green;
                                        String statusText = 'Normal';
                                        
                                        if (expired) {
                                          statusColor = Colors.red;
                                          statusText = 'Expired';
                                        } else if (soon) {
                                          statusColor = Colors.orange;
                                          statusText = 'Expiring Soon';
                                        }

                                        return DataRow(cells: [
                                          DataCell(Text(batch.id.toString())),
                                          DataCell(Text(batch.medicineName ?? 'ID: ${batch.medicineId}')),
                                          DataCell(Text(batch.batchNumber)),
                                          DataCell(Text(batch.expiryDate)),
                                          DataCell(Text(batch.quantity.toString())),
                                          DataCell(Text(batch.purchasePrice.toStringAsFixed(2))),
                                          DataCell(
                                            Chip(
                                              label: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                              backgroundColor: statusColor,
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                  tooltip: 'Edit',
                                                  onPressed: () => _showFormDialog(batch),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  tooltip: 'Delete',
                                                  onPressed: () => _confirmDelete(batch),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
