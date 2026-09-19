import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/ui_states.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/medicine_provider.dart';
import 'medicine_form_dialog.dart';
import '../models/medicine.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MedicineProvider>();
      provider.fetchSuppliers();
      provider.fetchMedicines();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<MedicineProvider>().searchMedicines(_searchController.text);
  }

  void _showFormDialog([Medicine? medicine]) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MedicineFormDialog(medicine: medicine),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(medicine == null ? 'Medicine added successfully' : 'Medicine updated successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(Medicine medicine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
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
        final success = await context.read<MedicineProvider>().deleteMedicine(medicine.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Medicine deleted successfully'),
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
    final provider = context.watch<MedicineProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Medicines',
              subtitle: 'Manage pharmacy catalog and pricing',
              action: FilledButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Medicine'),
              ),
            ),
            
            // Toolbar
            Row(
              children: [
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or category...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.fetchMedicines();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _onSearch(),
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: provider.isLoading ? null : _onSearch,
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    _searchController.clear();
                    provider.fetchMedicines();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: provider.isLoading
                  ? const LoadingState(message: 'Loading catalog...')
                  : provider.errorMessage != null
                      ? ErrorState(
                          message: provider.errorMessage!,
                          onRetry: () => provider.fetchMedicines(),
                        )
                      : provider.medicines.isEmpty
                          ? const EmptyState(
                              title: 'No medicines found',
                              message: 'Try adjusting your search or add a new medicine.',
                              icon: Icons.medical_services_outlined,
                            )
                          : DataTableCard(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('NAME')),
                                  DataColumn(label: Text('CATEGORY')),
                                  DataColumn(label: Text('MANUFACTURER')),
                                  DataColumn(label: Text('SUPPLIER')),
                                  DataColumn(label: Text('UNIT PRICE', textAlign: TextAlign.right)),
                                  DataColumn(label: Text('ACTIONS', textAlign: TextAlign.right)),
                                ],
                                rows: provider.medicines.map((med) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('#${med.id}', style: const TextStyle(color: Colors.grey))),
                                      DataCell(Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(med.category, style: const TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      DataCell(Text(med.manufacturer ?? '-')),
                                      DataCell(Text(med.supplierName ?? '-')),
                                      DataCell(
                                        Container(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            CurrencyFormatter.format(med.unitPrice),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                                              onPressed: () => _showFormDialog(med),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                                              tooltip: 'Delete',
                                              onPressed: () => _confirmDelete(med),
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
