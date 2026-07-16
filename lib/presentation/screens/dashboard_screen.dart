import 'package:flutter/material.dart';
import '../widgets/layout/responsive_scaffold.dart';
import '../widgets/core/epicordia_brand.dart';
import '../widgets/core/epicordia_button.dart';
import '../widgets/core/epicordia_card.dart';


class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveScaffold(
      appBar: const EpicordiaAppBar(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Widget Gallery', style: theme.textTheme.displayLarge),
          const SizedBox(height: 8),
          Text('Testing the UI foundations for Phase 3', style: theme.textTheme.bodyLarge),
          const Divider(height: 48),

          // Typography
          Text('Typography', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Display Large 32/700', style: theme.textTheme.displayLarge),
          Text('Display Medium 24/700', style: theme.textTheme.displayMedium),
          Text('Title Large 20/600', style: theme.textTheme.titleLarge),
          Text('Body Large 15/400', style: theme.textTheme.bodyLarge),
          Text('Body Medium 15/600', style: theme.textTheme.bodyMedium),
          Text('Body Small 13/400', style: theme.textTheme.bodySmall),
          Text('LABEL SMALL 12/600', style: theme.textTheme.labelSmall),
          const Divider(height: 48),

          // Buttons
          Text('Buttons', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              EpicordiaButton(label: 'Primary Button', onPressed: () {}),
              EpicordiaButton(label: 'Secondary Button', type: EpicordiaButtonType.secondary, onPressed: () {}),
              EpicordiaButton(label: 'Destructive Button', type: EpicordiaButtonType.destructive, onPressed: () {}),
              EpicordiaButton(label: 'Ghost Button', type: EpicordiaButtonType.ghost, onPressed: () {}),
              EpicordiaButton(label: 'With Icon', icon: Icons.star, onPressed: () {}),
            ],
          ),
          const Divider(height: 48),

          // Inputs
          Text('Inputs', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'STANDARD INPUT', hintText: 'Enter some text...'),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'MULTILINE INPUT', hintText: 'Type a longer description here...'),
            maxLines: 3,
          ),
          const Divider(height: 48),

          // Cards
          Text('Cards', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: EpicordiaCard(
                  onTap: () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Standard Card', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Just a normal card on the canvas', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: EpicordiaCard(
                  indicatorColor: theme.colorScheme.error,
                  onTap: () {},
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Urgent Card', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Has an error-colored stripe', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
