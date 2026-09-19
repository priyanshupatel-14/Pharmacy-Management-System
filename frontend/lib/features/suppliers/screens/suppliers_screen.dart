import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/ui_states.dart';
import '../../../core/widgets/data_table_card.dart';
import '../providers/supplier_provider.dart';
import 'supplier_form_dialog.dart';
import '../models/supplier.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().fetchSuppliers();
    });
  }

  void _showFormDialog([Supplier? supplier]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupplierFormDialog(supplier: supplier),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(supplier == null ? 'Supplier added successfully' : 'Supplier updated successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(Supplier supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
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
        final success = await context.read<SupplierProvider>().deleteSupplier(supplier.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Supplier deleted successfully'),
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
    final provider = context.watch<SupplierProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Suppliers',
              subtitle: 'Manage pharmaceutical suppliers and contacts',
              action: FilledButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Supplier'),
              ),
            ),
            
            // Toolbar
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => provider.fetchSuppliers(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: provider.isLoading
                  ? const LoadingState(message: 'Loading suppliers...')
                  : provider.errorMessage != null
                      ? ErrorState(
                          message: provider.errorMessage!,
                          onRetry: () => provider.fetchSuppliers(),
                        )
                      : provider.suppliers.isEmpty
                          ? const EmptyState(
                              title: 'No suppliers found',
                              message: 'Add a new supplier to get started.',
                              icon: Icons.local_shipping_outlined,
                            )
                          : DataTableCard(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('NAME')),
                                  DataColumn(label: Text('PHONE')),
                                  DataColumn(label: Text('EMAIL')),
                                  DataColumn(label: Text('ADDRESS')),
                                  DataColumn(label: Text('ACTIONS', textAlign: TextAlign.right)),
                                ],
                                rows: provider.suppliers.map((sup) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('#${sup.id}', style: const TextStyle(color: Colors.grey))),
                                      DataCell(Text(sup.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(sup.phone ?? '-')),
                                      DataCell(Text(sup.email ?? '-')),
                                      DataCell(
                                        SizedBox(
                                          width: 250,
                                          child: Text(
                                            sup.address ?? '-',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 18),
                                              tooltip: 'Edit',
                                              onPressed: () => _showFormDialog(sup),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                              tooltip: 'Delete',
                                              onPressed: () => _confirmDelete(sup),
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
