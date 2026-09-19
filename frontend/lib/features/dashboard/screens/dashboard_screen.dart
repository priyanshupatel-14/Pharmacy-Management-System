import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/ui_states.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      body: dashboard.isLoading
          ? const LoadingState(message: 'Loading dashboard data...')
          : dashboard.errorMessage != null
              ? ErrorState(
                  message: dashboard.errorMessage!,
                  onRetry: () => context.read<DashboardProvider>().fetchDashboardData(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: 'Dashboard Overview',
                        subtitle: 'Welcome back, ${auth.fullName ?? auth.username}. Here is what is happening today.',
                        action: FilledButton.icon(
                          onPressed: () => context.read<DashboardProvider>().fetchDashboardData(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ),
                      
                      // KPI Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 4;
                          if (constraints.maxWidth < 1200) crossAxisCount = 3;
                          if (constraints.maxWidth < 900) crossAxisCount = 2;
                          if (constraints.maxWidth < 600) crossAxisCount = 1;

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: crossAxisCount == 1 ? 2.5 : 2.0,
                            children: [
                              KpiCard(
                                title: 'Total Sales',
                                value: CurrencyFormatter.format(dashboard.totalSales),
                                icon: Icons.insights,
                                color: AppTheme.primaryColor,
                              ),
                              KpiCard(
                                title: 'Total Inventory',
                                value: dashboard.totalStock.toString(),
                                subtitle: '${dashboard.totalMedicines} unique items',
                                icon: Icons.inventory_2_outlined,
                                color: AppTheme.secondaryColor,
                              ),
                              KpiCard(
                                title: 'Low Stock Alerts',
                                value: dashboard.lowStockCount.toString(),
                                icon: Icons.warning_amber_rounded,
                                color: Colors.orange.shade600,
                              ),
                              KpiCard(
                                title: 'Expiring Soon',
                                value: dashboard.expiringSoonCount.toString(),
                                subtitle: '${dashboard.expiredBatchesCount} already expired',
                                icon: Icons.event_busy_outlined,
                                color: Colors.red.shade600,
                              ),
                            ],
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tables Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 900) {
                            return Column(
                              children: [
                                _buildRecentSalesTable(dashboard),
                                const SizedBox(height: 24),
                                _buildLowStockTable(dashboard),
                              ],
                            );
                          }
                          
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildRecentSalesTable(dashboard),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: _buildLowStockTable(dashboard),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRecentSalesTable(DashboardProvider dashboard) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Sales',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Last 5 transactions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (dashboard.recentSales.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: EmptyState(
                title: 'No sales yet',
                message: 'Sales transactions will appear here.',
                icon: Icons.receipt_long_outlined,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth > 500 ? constraints.maxWidth : 500,
                    ),
                    child: Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(), // ID
                        1: FlexColumnWidth(2), // Date
                        2: FlexColumnWidth(2), // User ID
                        3: FlexColumnWidth(1.5), // Amount
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                          ),
                          children: [
                            _buildTableHeader('ID', context),
                            _buildTableHeader('DATE', context),
                            _buildTableHeader('USER ID', context),
                            _buildTableHeader('AMOUNT', context, isRightAlign: true),
                          ],
                        ),
                        ...dashboard.recentSales.map((sale) {
                          final saleDate = sale['saleDate'] != null
                              ? DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse('${sale['saleDate']}Z').toLocal())
                              : 'N/A';
                          final amount = (sale['totalAmount'] as num?)?.toDouble() ?? 0.0;

                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                            ),
                            children: [
                              _buildTableCell('#${sale['id']}', context),
                              _buildTableCell(saleDate, context),
                              _buildTableCell('User ${sale['userId']}', context),
                              _buildTableCell(
                                CurrencyFormatter.format(amount),
                                context,
                                isRightAlign: true,
                                isBold: true,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text, BuildContext context, {bool isRightAlign = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        text,
        textAlign: isRightAlign ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).dataTableTheme.headingTextStyle ?? 
            const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTableCell(String text, BuildContext context, {bool isRightAlign = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        text,
        textAlign: isRightAlign ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).dataTableTheme.dataTextStyle?.copyWith(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ) ??
            TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: isBold ? FontWeight.w600 : FontWeight.normal),
      ),
    );
  }

  Widget _buildLowStockTable(DashboardProvider dashboard) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Critical Stock',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const StatusBadge(label: 'Action Needed', status: BadgeStatus.error),
              ],
            ),
          ),
          const Divider(height: 1),
          if (dashboard.lowStockItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: EmptyState(
                title: 'Stock is healthy',
                message: 'No items are currently running low.',
                icon: Icons.check_circle_outline,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('MEDICINE')),
                  DataColumn(label: Text('STOCK')),
                ],
                rows: dashboard.lowStockItems.map((item) {
                  final name = item['name'] ?? 'Unknown';
                  final stock = item['totalStock']?.toString() ?? '0';
                  
                  return DataRow(cells: [
                    DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(stock, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_downward, size: 14, color: Colors.red.shade700),
                        ],
                      )
                    ),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
