import 'package:flutter/material.dart';
import '../widgets/responsive_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Epicordia'),
      ),
      body: ResponsiveLayout(
        compact: _buildCompact(context),
        medium: _buildMedium(context),
        expanded: _buildExpanded(context),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Hello world (Compact Layout)'),
          const SizedBox(height: 16),
          Text(
            'Bottom Navigation will go here.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMedium(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          color: Theme.of(context).cardColor,
          child: const Center(child: Text('Nav Rail', textAlign: TextAlign.center,)),
        ),
        const VerticalDivider(width: 1),
        const Expanded(
          child: Center(
            child: Text('Hello world (Medium Layout)'),
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 240,
          color: Theme.of(context).cardColor,
          child: const Center(child: Text('Sidebar')),
        ),
        const VerticalDivider(width: 1),
        const Expanded(
          child: Center(
            child: Text('Hello world (Expanded Layout)'),
          ),
        ),
      ],
    );
  }
}
