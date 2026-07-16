import 'package:flutter/material.dart';
import '../widgets/core/epicordia_brand.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _theme = 'Light';
  String _defaultView = 'Canvas';
  bool _appLock = true;
  bool _backup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EpicordiaColors.surfaceAppLight,
      appBar: AppBar(
        backgroundColor: EpicordiaColors.surfaceAppLight,
        elevation: 0,
        titleSpacing: 20,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: const EpicordiaLogo(size: 18),
        ),
        leadingWidth: 160,
        title: const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: EpicordiaColors.textPrimaryLight), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
          children: [
            // ── Appearance ──────────────────────────────────────
            _SectionHeader(icon: Icons.palette_outlined, label: 'Appearance'),
            const SizedBox(height: 10),
            _Card(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme', style: TextStyle(fontSize: 14, color: EpicordiaColors.textSecondaryLight)),
                const SizedBox(height: 12),
                _SegmentedToggle(
                  options: const ['Light', 'Dark', 'System'],
                  selected: _theme,
                  onSelect: (v) => setState(() => _theme = v),
                ),
              ],
            )),

            const SizedBox(height: 24),

            // ── Default View ─────────────────────────────────────
            _SectionHeader(icon: Icons.space_dashboard_outlined, label: 'Default View'),
            const SizedBox(height: 10),
            _Card(child: Column(
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
            )),

            const SizedBox(height: 24),

            // ── Privacy & Security ────────────────────────────────
            _SectionHeader(icon: Icons.shield_outlined, label: 'Privacy & Security'),
            const SizedBox(height: 10),
            _Card(child: Column(
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
                  labelColor: EpicordiaColors.blue600,
                  showChevron: true,
                  onTap: () {},
                ),
              ],
            )),

            const SizedBox(height: 24),

            // ── Data & Backup ─────────────────────────────────────
            _SectionHeader(icon: Icons.cloud_outlined, label: 'Data & Backup'),
            const SizedBox(height: 10),
            _Card(child: Column(
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
                          side: const BorderSide(color: EpicordiaColors.borderStrongLight),
                          foregroundColor: EpicordiaColors.textPrimaryLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Export All Data', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: EpicordiaColors.errorLight),
                          foregroundColor: EpicordiaColors.errorLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Clear Cache', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            )),

            const SizedBox(height: 24),

            // ── About ─────────────────────────────────────────────
            _SectionHeader(icon: Icons.info_outline, label: 'About'),
            const SizedBox(height: 10),
            _Card(child: Column(
              children: [
                _InfoRow(label: 'Version', value: 'v2.4.0-stable', showDivider: true),
                _ActionRow(label: 'Terms of Service', icon: Icons.open_in_new, onTap: () {}, showChevron: false),
              ],
            )),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: EpicordiaColors.textSecondaryLight),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: EpicordiaColors.textPrimaryLight)),
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
    return Container(
      decoration: BoxDecoration(
        color: EpicordiaColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EpicordiaColors.borderSubtleLight),
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
  const _SegmentedToggle({required this.options, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((opt) {
        final active = opt == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? EpicordiaColors.blue600 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? EpicordiaColors.blue600 : EpicordiaColors.borderSubtleLight),
              ),
              child: Text(opt, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : EpicordiaColors.textSecondaryLight)),
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
  const _RadioRow({required this.icon, required this.label, required this.selected, required this.onTap, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: EpicordiaColors.textSecondaryLight),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: EpicordiaColors.textPrimaryLight))),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? EpicordiaColors.blue600 : Colors.transparent,
                    border: Border.all(color: selected ? EpicordiaColors.blue600 : EpicordiaColors.borderStrongLight, width: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: EpicordiaColors.borderSubtleLight),
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
  const _SwitchRow({required this.icon, required this.label, required this.value, required this.onChanged, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: EpicordiaColors.textSecondaryLight),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: EpicordiaColors.textPrimaryLight))),
            Switch(value: value, onChanged: onChanged, activeThumbColor: EpicordiaColors.blue600),
          ],
        ),
        if (showDivider) const Divider(height: 1, color: EpicordiaColors.borderSubtleLight),
      ],
    );
  }
}

// ── Action row ────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool showChevron;
  final Color? labelColor;
  const _ActionRow({required this.label, required this.icon, required this.onTap, this.showChevron = true, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: labelColor ?? EpicordiaColors.textSecondaryLight),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor ?? EpicordiaColors.textPrimaryLight))),
            if (showChevron) const Icon(Icons.chevron_right, size: 18, color: EpicordiaColors.textTertiaryLight),
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
  const _InfoRow({required this.label, required this.value, this.showDivider = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: EpicordiaColors.textPrimaryLight))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: EpicordiaColors.surfaceSunkenLight, borderRadius: BorderRadius.circular(6)),
                child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EpicordiaColors.textSecondaryLight)),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: EpicordiaColors.borderSubtleLight),
      ],
    );
  }
}
