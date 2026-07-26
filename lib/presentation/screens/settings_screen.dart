import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/core/epicordia_brand.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _defaultView = 'Canvas';
  bool _appLock = true;
  bool _backup = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final themeNotifier = ref.read(themeModeProvider.notifier);
    final selectedThemeString = themeNotifier.currentModeString;

    final textPrimary = isDark ? EpicordiaColors.textPrimaryDark : EpicordiaColors.textPrimaryLight;
    final bgApp = isDark ? EpicordiaColors.surfaceAppDark : EpicordiaColors.surfaceAppLight;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        backgroundColor: bgApp,
        elevation: 0,
        titleSpacing: 20,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: EpicordiaLogo(size: 18),
        ),
        leadingWidth: 160,
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textPrimary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          children: [
            // ── Appearance ──────────────────────────────────────
            const _SectionHeader(icon: Icons.palette_outlined, label: 'Appearance'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? EpicordiaColors.textSecondaryDark
                          : EpicordiaColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SegmentedToggle(
                    options: const ['Light', 'Dark', 'System'],
                    selected: selectedThemeString,
                    onSelect: (v) {
                      ref.read(themeModeProvider.notifier).setThemeMode(v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Default View ─────────────────────────────────────
            const _SectionHeader(
                icon: Icons.space_dashboard_outlined, label: 'Default View'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: ['Canvas', 'List', 'Focus'].map((view) {
                  final active = _defaultView == view;
                  return _RadioRow(
                    icon: view == 'Canvas'
                        ? Icons.brush_outlined
                        : view == 'List'
                            ? Icons.format_list_bulleted
                            : Icons.center_focus_strong_outlined,
                    label: '$view View',
                    selected: active,
                    onTap: () => setState(() => _defaultView = view),
                    showDivider: view != 'Focus',
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── Privacy & Security ────────────────────────────────
            const _SectionHeader(
                icon: Icons.shield_outlined, label: 'Privacy & Security'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.lock_outline,
                    label: 'App Lock',
                    value: _appLock,
                    onChanged: (v) => setState(() => _appLock = v),
                    showDivider: true,
                  ),
                  _ActionRow(
                    icon: Icons.pin_outlined,
                    label: 'Change PIN',
                    labelColor: isDark
                        ? EpicordiaColors.blue300
                        : EpicordiaColors.blue600,
                    showChevron: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Data & Backup ─────────────────────────────────────
            const _SectionHeader(
                icon: Icons.cloud_outlined, label: 'Data & Backup'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _SwitchRow(
                    icon: Icons.backup_outlined,
                    label: 'Backup to Cloud',
                    value: _backup,
                    onChanged: (v) => setState(() => _backup = v),
                    showDivider: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? EpicordiaColors.borderStrongDark
                                  : EpicordiaColors.borderStrongLight,
                            ),
                            foregroundColor: textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Export All Data',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? EpicordiaColors.errorDark
                                  : EpicordiaColors.errorLight,
                            ),
                            foregroundColor: isDark
                                ? EpicordiaColors.errorDark
                                : EpicordiaColors.errorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Clear Cache',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── About ─────────────────────────────────────────────
            const _SectionHeader(icon: Icons.info_outline, label: 'About'),
            const SizedBox(height: 10),
            const _Card(
              child: Column(
                children: [
                  _InfoRow(
                      label: 'Version',
                      value: 'v2.4.0-stable',
                      showDivider: true),
                  _ActionRow(
                      label: 'Terms of Service',
                      icon: Icons.open_in_new,
                      onTap: null,
                      showChevron: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable section header ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;

    return Row(
      children: [
        Icon(icon, size: 16, color: textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Card wrapper ──────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? EpicordiaColors.surfaceCardDark
            : EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? EpicordiaColors.borderSubtleDark
              : EpicordiaColors.borderSubtleLight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: child,
    );
  }
}

// ── Segmented toggle ──────────────────────────────────────────────────
class _SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;
  const _SegmentedToggle({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;

    return Row(
      children: options.map((opt) {
        final active = opt == selected;
        final activeColor = isDark
            ? EpicordiaColors.blue500
            : EpicordiaColors.blue600;

        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active ? activeColor : borderSubtle,
                ),
              ),
              child: Text(
                opt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Radio row ─────────────────────────────────────────────────────────
class _RadioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;
  const _RadioRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final borderStrong = isDark
        ? EpicordiaColors.borderStrongDark
        : EpicordiaColors.borderStrongLight;
    final activeColor = isDark
        ? EpicordiaColors.blue500
        : EpicordiaColors.blue600;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? activeColor : Colors.transparent,
                    border: Border.all(
                      color: selected ? activeColor : borderStrong,
                      width: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: borderSubtle),
      ],
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final activeColor = isDark
        ? EpicordiaColors.blue500
        : EpicordiaColors.blue600;

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: textPrimary),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: activeColor,
            ),
          ],
        ),
        if (showDivider) Divider(height: 1, color: borderSubtle),
      ],
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? labelColor;
  const _ActionRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.showChevron = true,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final textTertiary = isDark
        ? EpicordiaColors.textTertiaryDark
        : EpicordiaColors.textTertiaryLight;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: labelColor ?? textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? textPrimary,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, size: 18, color: textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? EpicordiaColors.textSecondaryDark
        : EpicordiaColors.textSecondaryLight;
    final textPrimary = isDark
        ? EpicordiaColors.textPrimaryDark
        : EpicordiaColors.textPrimaryLight;
    final borderSubtle = isDark
        ? EpicordiaColors.borderSubtleDark
        : EpicordiaColors.borderSubtleLight;
    final surfaceSunken = isDark
        ? EpicordiaColors.surfaceSunkenDark
        : EpicordiaColors.surfaceSunkenLight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: surfaceSunken,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: borderSubtle),
      ],
    );
  }
}
