import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
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
          backgroundColor: Colors.green,
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await context.read<MedicineProvider>().deleteMedicine(medicine.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted successfully'), backgroundColor: Colors.green),
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
    final provider = context.watch<MedicineProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Medicines',
              subtitle: 'Manage pharmacy inventory and catalog',
              action: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh List',
                onPressed: () {
                  _searchController.clear();
                  provider.fetchMedicines();
                },
              ),
            ),
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search medicines by name or category...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.fetchMedicines();
                        },
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _onSearch,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Text('Search'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Data Table / List
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
                      : provider.medicines.isEmpty
                          ? const Center(child: Text('No medicines found.'))
                          : Card(
                              elevation: 2,
                              child: ListView(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('ID')),
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Category')),
                                        DataColumn(label: Text('Manufacturer')),
                                        DataColumn(label: Text('Unit Price (₹)')),
                                        DataColumn(label: Text('Supplier')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: provider.medicines.map((med) {
                                        return DataRow(cells: [
                                          DataCell(Text(med.id.toString())),
                                          DataCell(Text(med.name)),
                                          DataCell(Text(med.category)),
                                          DataCell(Text(med.manufacturer ?? '-')),
                                          DataCell(Text(med.unitPrice.toStringAsFixed(2))),
                                          DataCell(Text(med.supplierName ?? '-')),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                  tooltip: 'Edit',
                                                  onPressed: () => _showFormDialog(med),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  tooltip: 'Delete',
                                                  onPressed: () => _confirmDelete(med),
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
