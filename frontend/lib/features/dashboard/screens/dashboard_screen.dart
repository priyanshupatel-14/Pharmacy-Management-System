import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/page_header.dart';
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
    // Fetch data on load
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
          ? const Center(child: CircularProgressIndicator())
          : dashboard.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dashboard.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<DashboardProvider>().fetchDashboardData(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageHeader(
                        title: 'Dashboard',
                        subtitle: 'Welcome, ${auth.fullName ?? auth.username}!',
                        action: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => context.read<DashboardProvider>().fetchDashboardData(),
                          tooltip: 'Refresh',
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
                            return GridView.count(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                              children: [
                                _buildStatCard(
                                  context,
                                  title: 'Total Medicines',
                                  value: dashboard.totalMedicines.toString(),
                                  icon: Icons.medical_services,
                                  color: Colors.blue,
                                ),
                                _buildStatCard(
                                  context,
                                  title: 'Total Stock',
                                  value: dashboard.totalStock.toString(),
                                  icon: Icons.inventory,
                                  color: Colors.teal,
                                ),
                                _buildStatCard(
                                  context,
                                  title: 'Total Sales (₹)',
                                  value: dashboard.totalSales.toStringAsFixed(2),
                                  icon: Icons.attach_money,
                                  color: Colors.green,
                                ),
                                _buildStatCard(
                                  context,
                                  title: 'Low Stock',
                                  value: dashboard.lowStockCount.toString(),
                                  icon: Icons.warning_amber,
                                  color: Colors.orange,
                                ),
                                _buildStatCard(
                                  context,
                                  title: 'Expiring Soon',
                                  value: dashboard.expiringSoonCount.toString(),
                                  icon: Icons.schedule,
                                  color: Colors.amber,
                                ),
                                _buildStatCard(
                                  context,
                                  title: 'Expired Batches',
                                  value: dashboard.expiredBatchesCount.toString(),
                                  icon: Icons.error_outline,
                                  color: Colors.red,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
