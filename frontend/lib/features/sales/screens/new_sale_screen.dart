import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../models/sale_request.dart';
import '../../stock/models/stock_info.dart';
import '../../batches/models/medicine_batch.dart';

class LocalSaleItem {
  final MedicineBatch batch;
  final String medicineName;
  final double unitPrice;
  int quantity;

  LocalSaleItem({
    required this.batch,
    required this.medicineName,
    required this.unitPrice,
    required this.quantity,
  });

  double get subtotal => unitPrice * quantity;
}

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final List<LocalSaleItem> _billItems = [];
  
  StockInfo? _selectedStock;
  MedicineBatch? _selectedBatch;
  final TextEditingController _qtyController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().fetchAvailableStockAndMedicines();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_selectedStock == null || _selectedBatch == null) return;
    
    final qtyStr = _qtyController.text.trim();
    if (qtyStr.isEmpty) {
      _showError('Enter quantity');
      return;
    }
    
    final qty = int.tryParse(qtyStr);
    if (qty == null || qty <= 0) {
      _showError('Enter valid quantity');
      return;
    }

    if (qty > _selectedBatch!.quantity) {
      _showError('Insufficient stock for this batch');
      return;
    }

    if (_selectedBatch!.isExpired) {
      _showError('Cannot sell expired batch');
      return;
    }

    // Check if already in bill
    final existingIndex = _billItems.indexWhere((i) => i.batch.id == _selectedBatch!.id);
    if (existingIndex >= 0) {
      final newQty = _billItems[existingIndex].quantity + qty;
      if (newQty > _selectedBatch!.quantity) {
        _showError('Total quantity exceeds batch stock');
        return;
      }
      setState(() {
        _billItems[existingIndex].quantity = newQty;
      });
    } else {
      // Find unit price from medicines list
      final med = context.read<SaleProvider>().medicines.firstWhere(
            (m) => m.id == _selectedStock!.medicineId,
            orElse: () => throw Exception('Medicine not found'),
          );
          
      setState(() {
        _billItems.add(LocalSaleItem(
          batch: _selectedBatch!,
          medicineName: _selectedStock!.medicineName,
          unitPrice: med.unitPrice,
          quantity: qty,
        ));
      });
    }

    _qtyController.clear();
    setState(() {
      _selectedBatch = null;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _billItems.removeAt(index);
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _submitSale() async {
    if (_billItems.isEmpty) {
      _showError('Add at least one item');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final requests = _billItems.map((e) => SaleItemRequest(
        batchId: e.batch.id,
        quantity: e.quantity,
      )).toList();

      final success = await context.read<SaleProvider>().createSale(requests);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SaleProvider>();
    double total = _billItems.fold(0, (sum, item) => sum + item.subtotal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Item Selection
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Add Item to Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<StockInfo>(
                        decoration: const InputDecoration(labelText: 'Select Medicine'),
                        initialValue: _selectedStock,
                        items: provider.availableStock.where((s) => s.totalStock > 0).map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.medicineName));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStock = val;
                            _selectedBatch = null; // Reset batch
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<MedicineBatch>(
                        decoration: const InputDecoration(labelText: 'Select Batch'),
                        initialValue: _selectedBatch,
                        items: _selectedStock?.batches.where((b) => b.quantity > 0).map((b) {
                          final label = '${b.batchNumber} (Stock: ${b.quantity})${b.isExpired ? ' - EXPIRED' : ''}';
                          return DropdownMenuItem(value: b, child: Text(label));
                        }).toList() ?? [],
                        onChanged: _selectedStock == null ? null : (val) {
                          setState(() {
                            _selectedBatch = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _qtyController,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right Side: Bill Details
            Expanded(
              flex: 2,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _billItems.isEmpty
                            ? const Center(child: Text('No items added yet.'))
                            : ListView(
                                children: [
                                  DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Item')),
                                      DataColumn(label: Text('Batch')),
                                      DataColumn(label: Text('Price')),
                                      DataColumn(label: Text('Qty')),
                                      DataColumn(label: Text('Subtotal')),
                                      DataColumn(label: Text('')),
                                    ],
                                    rows: _billItems.asMap().entries.map((entry) {
                                      final i = entry.key;
                                      final item = entry.value;
                                      return DataRow(cells: [
                                        DataCell(Text(item.medicineName)),
                                        DataCell(Text(item.batch.batchNumber)),
                                        DataCell(Text('₹${item.unitPrice.toStringAsFixed(2)}')),
                                        DataCell(Text(item.quantity.toString())),
                                        DataCell(Text('₹${item.subtotal.toStringAsFixed(2)}')),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                                            onPressed: () => _removeItem(i),
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ],
                              ),
                      ),
                      const Divider(thickness: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: _isSubmitting || _billItems.isEmpty ? null : _submitSale,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Complete Sale', style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
