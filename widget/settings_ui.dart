import 'package:app/app_consts.dart';
import 'package:flutter/material.dart';

/// Shared layout, typography, and control styles for Settings screens.
class SettingsStyles {
  static const double pagePadding = 16;
  static const double sectionGap = 24;
  static const double itemGap = 12;
  static const double buttonHeight = 44;

  static TextStyle get pageTitle => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.3,
        color: Colors.black87,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );

  static TextStyle get itemTitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );

  static TextStyle get itemSubtitle => TextStyle(
        fontSize: 13,
        height: 1.3,
        color: Colors.grey.shade600,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 13,
        color: Colors.grey.shade600,
      );

  static ButtonStyle filledButton({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: backgroundColor ?? AppConst.mainColor,
      foregroundColor: foregroundColor ?? AppConst.fontColor,
      disabledBackgroundColor: AppConst.mainColor.withOpacity(0.35),
      disabledForegroundColor: AppConst.fontColor.withOpacity(0.85),
      minimumSize: const Size(0, buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.borderRadius),
      ),
    );
  }

  static ButtonStyle outlinedButton({Color? foregroundColor}) {
    final color = foregroundColor ?? AppConst.mainColor;
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      disabledForegroundColor: color.withOpacity(0.4),
      minimumSize: const Size(0, buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      side: BorderSide(color: color.withOpacity(0.35)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConst.borderRadius),
      ),
    );
  }

  static InputDecoration dropdownDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.borderRadius),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConst.borderRadius),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.8)),
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    Key? key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: 12),
  }) : super(key: key);

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: SettingsStyles.sectionTitle)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 14),
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SettingsPrimaryButton extends StatelessWidget {
  const SettingsPrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.expanded = false,
    this.icon,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );
    final button = ElevatedButton(
      style: SettingsStyles.filledButton(),
      onPressed: onPressed,
      child: child,
    );
    if (!expanded) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}

class SettingsSecondaryButton extends StatelessWidget {
  const SettingsSecondaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.expanded = false,
    this.icon,
  }) : super(key: key);

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );
    final button = OutlinedButton(
      style: SettingsStyles.outlinedButton(),
      onPressed: onPressed,
      child: child,
    );
    if (!expanded) {
      return button;
    }
    return SizedBox(width: double.infinity, child: button);
  }
}

class SettingsButtonRow extends StatelessWidget {
  const SettingsButtonRow({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class SettingsListRow extends StatelessWidget {
  const SettingsListRow({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppConst.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppConst.mainColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SettingsStyles.itemTitle),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsStyles.itemSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsHeroBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsHeroBar({
    Key? key,
    required this.tag,
    required this.title,
    required this.onBack,
  }) : super(key: key);

  final String tag;
  final String title;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: Material(
        color: AppConst.mainColor,
        elevation: 1,
        child: SizedBox(
          height: preferredSize.height,
          child: InkWell(
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: AppConst.fontColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppConst.fontColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsDropdownField<T> extends StatelessWidget {
  const SettingsDropdownField({
    Key? key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: SettingsStyles.dropdownDecoration(label: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          isDense: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
