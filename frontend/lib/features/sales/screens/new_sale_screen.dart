import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/ui_states.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
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
      _showError('Please enter a quantity');
      return;
    }
    
    final qty = int.tryParse(qtyStr);
    if (qty == null || qty <= 0) {
      _showError('Please enter a valid positive quantity');
      return;
    }

    if (qty > _selectedBatch!.quantity) {
      _showError('Insufficient stock. Only ${_selectedBatch!.quantity} available.');
      return;
    }

    if (_selectedBatch!.isExpired) {
      _showError('Cannot sell an expired batch');
      return;
    }

    // Check if already in bill
    final existingIndex = _billItems.indexWhere((i) => i.batch.id == _selectedBatch!.id);
    if (existingIndex >= 0) {
      final newQty = _billItems[existingIndex].quantity + qty;
      if (newQty > _selectedBatch!.quantity) {
        _showError('Total quantity in bill exceeds available stock');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitSale() async {
    if (_billItems.isEmpty) {
      _showError('Add at least one item to complete the sale');
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
          SnackBar(
            content: const Text('Sale completed successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
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
        title: const Text('New Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Item Selection
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Add to Cart', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Select medicine and batch to add to the current bill.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<StockInfo>(
                        decoration: const InputDecoration(labelText: 'Medicine'),
                        initialValue: _selectedStock,
                        isExpanded: true,
                        items: provider.availableStock.where((s) => s.totalStock > 0).map((s) {
                          return DropdownMenuItem(value: s, child: Text(s.medicineName));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStock = val;
                            _selectedBatch = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<MedicineBatch>(
                        decoration: const InputDecoration(labelText: 'Batch'),
                        initialValue: _selectedBatch,
                        isExpanded: true,
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
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _qtyController,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        onFieldSubmitted: (_) => _addItem(),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add to Bill'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Right Side: Bill Details
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current Bill', style: Theme.of(context).textTheme.titleLarge),
                          Text('${_billItems.length} items', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _billItems.isEmpty
                            ? const EmptyState(
                                title: 'Cart is empty',
                                message: 'Select items from the left to add them to the bill.',
                                icon: Icons.shopping_cart_outlined,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderLight),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(AppTheme.backgroundColor),
                                      columns: const [
                                        DataColumn(label: Text('ITEM')),
                                        DataColumn(label: Text('BATCH')),
                                        DataColumn(label: Text('PRICE')),
                                        DataColumn(label: Text('QTY')),
                                        DataColumn(label: Text('SUBTOTAL', textAlign: TextAlign.right)),
                                        DataColumn(label: Text('')),
                                      ],
                                      rows: _billItems.asMap().entries.map((entry) {
                                        final i = entry.key;
                                        final item = entry.value;
                                        return DataRow(cells: [
                                          DataCell(Text(item.medicineName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                          DataCell(Text(item.batch.batchNumber)),
                                          DataCell(Text(CurrencyFormatter.format(item.unitPrice))),
                                          DataCell(Text(item.quantity.toString())),
                                          DataCell(
                                            Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                CurrencyFormatter.format(item.subtotal),
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400, size: 18),
                                              tooltip: 'Remove',
                                              onPressed: () => _removeItem(i),
                                            ),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount Payable', style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              CurrencyFormatter.format(total),
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _isSubmitting || _billItems.isEmpty ? null : _submitSale,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Complete Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
