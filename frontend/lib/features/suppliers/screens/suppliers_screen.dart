import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
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
          backgroundColor: Colors.green,
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final success = await context.read<SupplierProvider>().deleteSupplier(supplier.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier deleted successfully'), backgroundColor: Colors.green),
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
    final provider = context.watch<SupplierProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Supplier Management',
              subtitle: 'Manage pharmacy suppliers and their contact information',
              action: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh List',
                onPressed: () => provider.fetchSuppliers(),
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
                      : provider.suppliers.isEmpty
                          ? const Center(child: Text('No suppliers found.'))
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
                                        DataColumn(label: Text('Phone')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Address')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: provider.suppliers.map((sup) {
                                        return DataRow(cells: [
                                          DataCell(Text(sup.id.toString())),
                                          DataCell(Text(sup.name)),
                                          DataCell(Text(sup.phone ?? '-')),
                                          DataCell(Text(sup.email ?? '-')),
                                          DataCell(
                                            SizedBox(
                                              width: 200,
                                              child: Text(
                                                sup.address ?? '-',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                  tooltip: 'Edit',
                                                  onPressed: () => _showFormDialog(sup),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  tooltip: 'Delete',
                                                  onPressed: () => _confirmDelete(sup),
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
