import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DataTableCard extends StatelessWidget {
  final Widget child;

  const DataTableCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width * 0.5), // ensures table stretches nicely if small
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerTheme: const DividerThemeData(
                color: AppTheme.borderLight,
                thickness: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
