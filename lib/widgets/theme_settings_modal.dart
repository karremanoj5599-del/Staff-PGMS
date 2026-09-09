import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ThemeSettingsModal extends StatelessWidget {
  const ThemeSettingsModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemeSettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Admin Settings',
                  style: TextStyle(
                    fontSize: 20 * theme.uiScale,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.text),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.separator),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Theme Mode
                Text(
                  'THEME MODE',
                  style: TextStyle(
                    fontSize: 12 * theme.uiScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Dark Mode',
                        isSelected: theme.themeMode == ThemeMode.dark,
                        onTap: () => theme.setThemeMode(ThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeButton(
                        label: 'Light Mode',
                        isSelected: theme.themeMode == ThemeMode.light,
                        onTap: () => theme.setThemeMode(ThemeMode.light),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Primary Color
                Text(
                  'PRIMARY COLOR',
                  style: TextStyle(
                    fontSize: 12 * theme.uiScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: AppTheme.primaryColors.map((color) {
                    final isSelected = theme.primaryColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () => theme.setPrimaryColor(color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 14),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(120),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 3. Typography Font
                Text(
                  'TYPOGRAPHY FONT',
                  style: TextStyle(
                    fontSize: 12 * theme.uiScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppTheme.supportedFonts.map((font) {
                    final isSelected = theme.fontFamily == font;
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 50) / 2,
                      child: InkWell(
                        onTap: () => theme.setFontFamily(font),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor.withAlpha(25) : colors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? theme.primaryColor : colors.cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              font,
                              style: TextStyle(
                                color: isSelected ? theme.primaryColor : colors.text,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14 * theme.uiScale,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // 4. UI Scale
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UI SCALE (BASE FONT SIZE)',
                      style: TextStyle(
                        fontSize: 12 * theme.uiScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(16 * theme.uiScale).round()}PX',
                      style: TextStyle(
                        fontSize: 13 * theme.uiScale,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: theme.uiScale,
                  min: 0.75,
                  max: 1.25,
                  divisions: 10,
                  activeColor: theme.primaryColor,
                  inactiveColor: colors.separator,
                  onChanged: (val) => theme.setUiScale(val),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Small (12px)', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                      Text('Default (16px)', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                      Text('Large (20px)', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final colors = theme.resolvedColors(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withAlpha(25) : colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.primaryColor : colors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? theme.primaryColor : colors.text,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14 * theme.uiScale,
            ),
          ),
        ),
      ),
    );
  }
}
