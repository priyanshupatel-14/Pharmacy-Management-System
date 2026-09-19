import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../medicines/screens/medicines_screen.dart';
import '../../suppliers/screens/suppliers_screen.dart';
import '../../stock/screens/stock_screen.dart';
import '../../batches/screens/batches_screen.dart';
import '../../sales/screens/sales_screen.dart';
import '../../staff/screens/staff_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  List<Widget> _screens = [];
  List<Map<String, dynamic>> _navItems = [];

  @override
  void initState() {
    super.initState();
    _initNavItems();
  }

  void _initNavItems() {
    final role = context.read<AuthProvider>().role;
    final isAdmin = role == 'ADMIN';

    _screens = [
      const DashboardScreen(),
      const MedicinesScreen(),
      const SuppliersScreen(),
      const StockScreen(),
      const BatchesScreen(),
      const SalesScreen(),
    ];

    _navItems = [
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.medical_services_outlined, 'activeIcon': Icons.medical_services, 'label': 'Medicines'},
      {'icon': Icons.local_shipping_outlined, 'activeIcon': Icons.local_shipping, 'label': 'Suppliers'},
      {'icon': Icons.inventory_2_outlined, 'activeIcon': Icons.inventory_2, 'label': 'Stock'},
      {'icon': Icons.category_outlined, 'activeIcon': Icons.category, 'label': 'Batches'},
      {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long, 'label': 'Sales'},
    ];

    if (isAdmin) {
      _screens.add(const StaffScreen());
      _navItems.add({'icon': Icons.people_outline, 'activeIcon': Icons.people, 'label': 'Staff'});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          if (isTablet) _buildNavigationRail(context),
          if (isDesktop || isTablet) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
      drawer: (!isDesktop && !isTablet) ? _buildDrawer(context) : null,
      appBar: (!isDesktop && !isTablet)
          ? AppBar(
              title: const Text('Pharmacy System'),
            )
          : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.surfaceColor,
      child: Column(
        children: [
          _buildBrandHeader(context),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return _buildSidebarItem(
                  icon: isSelected ? item['activeIcon'] : item['icon'],
                  label: item['label'],
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedIndex = index),
                );
              },
            ),
          ),
          const Divider(),
          _buildUserProfile(context),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surfaceColor,
      child: Column(
        children: [
          _buildBrandHeader(context),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return _buildSidebarItem(
                  icon: isSelected ? item['activeIcon'] : item['icon'],
                  label: item['label'],
                  isSelected: isSelected,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context); // Close drawer
                  },
                );
              },
            ),
          ),
          const Divider(),
          _buildUserProfile(context),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: AppTheme.surfaceColor,
      useIndicator: true,
      indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      destinations: _navItems.map((item) {
        return NavigationRailDestination(
          icon: Icon(item['icon'], color: AppTheme.textSecondary),
          selectedIcon: Icon(item['activeIcon'], color: AppTheme.primaryColor),
          label: Text(item['label']),
        );
      }).toList(),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.textSecondary),
              tooltip: 'Logout',
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_pharmacy, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              auth.pharmacyName ?? 'PharmacyOS',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: AppTheme.primaryColor.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Text(
              auth.username?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  auth.fullName ?? 'User',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  auth.role ?? 'Staff',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            color: AppTheme.textSecondary,
            tooltip: 'Logout',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}
