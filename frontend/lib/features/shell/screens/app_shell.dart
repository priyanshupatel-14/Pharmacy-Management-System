import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../medicines/screens/medicines_screen.dart';
import '../../suppliers/screens/suppliers_screen.dart';
import '../../stock/screens/stock_screen.dart';
import '../../batches/screens/batches_screen.dart';
import '../../sales/screens/sales_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Only one screen currently, others to be added later
    final List<Widget> screens = [
      const DashboardScreen(),
      const MedicinesScreen(),
      const SuppliersScreen(),
      const StockScreen(),
      const BatchesScreen(),
      const SalesScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            extended: MediaQuery.of(context).size.width >= 800,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.medical_services),
                label: Text('Medicines'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping),
                label: Text('Suppliers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory),
                label: Text('Stock'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text('Batches'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long),
                label: Text('Sales'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
