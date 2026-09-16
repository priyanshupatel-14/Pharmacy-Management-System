import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
import '../providers/sale_provider.dart';
import '../models/sale.dart';
import 'new_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().fetchSales();
    });
  }

  void _showSaleDetails(Sale sale) async {
    final provider = context.read<SaleProvider>();
    // Fetch details to get items
    final detailedSale = await provider.fetchSaleDetails(sale.id);

    if (!mounted) return;
    
    if (detailedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load sale details')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sale Details - #${detailedSale.id}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${detailedSale.saleDate}'),
              Text('Total Amount: ₹${detailedSale.totalAmount.toStringAsFixed(2)}'),
              if (detailedSale.userName != null) Text('Cashier: ${detailedSale.userName}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (detailedSale.items == null || detailedSale.items!.isEmpty)
                const Text('No items found.')
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Medicine')),
                      DataColumn(label: Text('Batch')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Qty')),
                      DataColumn(label: Text('Subtotal')),
                    ],
                    rows: detailedSale.items!.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.medicineName ?? '-')),
                        DataCell(Text(item.batchNumber ?? '-')),
                        DataCell(Text('₹${item.unitPrice.toStringAsFixed(2)}')),
                        DataCell(Text(item.quantity.toString())),
                        DataCell(Text('₹${item.subtotal.toStringAsFixed(2)}')),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SaleProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewSaleScreen()),
          );
          if (result == true) {
            provider.fetchSales();
          }
        },
        icon: const Icon(Icons.receipt),
        label: const Text('New Sale'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Sales History',
              subtitle: 'View past sales and generate new bills.',
              action: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Sales',
                onPressed: () => provider.fetchSales(),
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
                      : provider.sales.isEmpty
                          ? const Center(child: Text('No sales records found.'))
                          : Card(
                              elevation: 2,
                              child: ListView(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Sale ID')),
                                        DataColumn(label: Text('Date')),
                                        DataColumn(label: Text('Total Amount')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: provider.sales.map((sale) {
                                        return DataRow(cells: [
                                          DataCell(Text(sale.id.toString())),
                                          DataCell(Text(sale.saleDate)),
                                          DataCell(Text('₹${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.visibility, color: Colors.blue),
                                              tooltip: 'View Details',
                                              onPressed: () => _showSaleDetails(sale),
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
