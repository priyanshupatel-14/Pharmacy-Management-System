import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/ui_states.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/stock_provider.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().fetchStock();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Inventory Status',
              subtitle: 'Monitor stock levels and identify low inventory items',
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Low Stock Only', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  Switch(
                    value: provider.showLowStockOnly,
                    onChanged: (val) => provider.toggleLowStockFilter(val),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh',
                    onPressed: () => provider.fetchStock(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: provider.isLoading
                  ? const LoadingState(message: 'Checking inventory levels...')
                  : provider.errorMessage != null
                      ? ErrorState(
                          message: provider.errorMessage!,
                          onRetry: () => provider.fetchStock(),
                        )
                      : provider.stocks.isEmpty
                          ? EmptyState(
                              title: provider.showLowStockOnly ? 'No low stock' : 'No stock data',
                              message: provider.showLowStockOnly
                                  ? 'All your inventory is currently healthy.'
                                  : 'No stock data is available right now.',
                              icon: Icons.inventory_2_outlined,
                            )
                          : DataTableCard(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('MEDICINE')),
                                  DataColumn(label: Text('CATEGORY')),
                                  DataColumn(label: Text('AVAILABLE STOCK', textAlign: TextAlign.right)),
                                  DataColumn(label: Text('STATUS')),
                                ],
                                rows: provider.stocks.map((stock) {
                                  final isLow = stock.totalStock <= 10;
                                  return DataRow(
                                    cells: [
                                      DataCell(Text('#${stock.medicineId}', style: const TextStyle(color: Colors.grey))),
                                      DataCell(Text(stock.medicineName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(stock.category)),
                                      DataCell(
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            stock.totalStock.toString(),
                                            style: TextStyle(
                                              color: isLow ? Colors.red.shade700 : Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        StatusBadge(
                                          label: isLow ? 'Low Stock' : 'Healthy',
                                          status: isLow ? BadgeStatus.error : BadgeStatus.success,
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
