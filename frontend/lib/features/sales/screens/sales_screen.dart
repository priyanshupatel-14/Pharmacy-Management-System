import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/ui_states.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/utils/currency_formatter.dart';
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
    final detailedSale = await provider.fetchSaleDetails(sale.id);

    if (!mounted) return;
    
    if (detailedSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load sale details')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sale Receipt #${detailedSale.id}'),
        content: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date & Time', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(detailedSale.saleDate)),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Cashier', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(detailedSale.userName ?? 'System', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              if (detailedSale.items == null || detailedSale.items!.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No items found.'),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: detailedSale.items!.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = detailedSale.items![idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.medicineName ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Batch: ${item.batchNumber ?? '-'} • ${CurrencyFormatter.format(item.unitPrice)} x ${item.quantity}'),
                        trailing: Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    CurrencyFormatter.format(detailedSale.totalAmount),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).primaryColor),
                  ),
                ],
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Sales & Billing',
              subtitle: 'Process new transactions and view sales history',
              action: FilledButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewSaleScreen()),
                  );
                  if (result == true) {
                    provider.fetchSales();
                  }
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('New Sale'),
              ),
            ),
            
            // Toolbar
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () => provider.fetchSales(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: provider.isLoading
                  ? const LoadingState(message: 'Loading sales history...')
                  : provider.errorMessage != null
                      ? ErrorState(
                          message: provider.errorMessage!,
                          onRetry: () => provider.fetchSales(),
                        )
                      : provider.sales.isEmpty
                          ? const EmptyState(
                              title: 'No sales yet',
                              message: 'Create a new sale to see it listed here.',
                              icon: Icons.receipt_long_outlined,
                            )
                          : DataTableCard(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('RECEIPT NO')),
                                  DataColumn(label: Text('DATE & TIME')),
                                  DataColumn(label: Text('AMOUNT', textAlign: TextAlign.right)),
                                  DataColumn(label: Text('ACTIONS', textAlign: TextAlign.right)),
                                ],
                                rows: provider.sales.map((sale) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('#${sale.id}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(sale.saleDate)))),
                                      DataCell(
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            CurrencyFormatter.format(sale.totalAmount),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          alignment: Alignment.centerRight,
                                          child: IconButton(
                                            icon: const Icon(Icons.visibility_outlined, size: 18),
                                            tooltip: 'View Receipt',
                                            onPressed: () => _showSaleDetails(sale),
                                          ),
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
