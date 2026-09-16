import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            PageHeader(
              title: 'Current Inventory',
              subtitle: 'View overall stock levels and identify low-stock items',
              action: Row(
                children: [
                  const Text('Show Low Stock Only'),
                  Switch(
                    value: provider.showLowStockOnly,
                    onChanged: (val) => provider.toggleLowStockFilter(val),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Stock',
                    onPressed: () => provider.fetchStock(),
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
                      : provider.stocks.isEmpty
                          ? const Center(child: Text('No stock data available.'))
                          : Card(
                              elevation: 2,
                              child: ListView(
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Medicine ID')),
                                        DataColumn(label: Text('Medicine Name')),
                                        DataColumn(label: Text('Category')),
                                        DataColumn(label: Text('Total Stock')),
                                        DataColumn(label: Text('Status')),
                                      ],
                                      rows: provider.stocks.map((stock) {
                                        final isLow = stock.totalStock <= 10;
                                        return DataRow(cells: [
                                          DataCell(Text(stock.medicineId.toString())),
                                          DataCell(Text(stock.medicineName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                          DataCell(Text(stock.category)),
                                          DataCell(
                                            Text(
                                              stock.totalStock.toString(),
                                              style: TextStyle(
                                                color: isLow ? Colors.red : Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Chip(
                                              label: Text(
                                                isLow ? 'Low Stock' : 'In Stock',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                              backgroundColor: isLow ? Colors.red : Colors.green,
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
