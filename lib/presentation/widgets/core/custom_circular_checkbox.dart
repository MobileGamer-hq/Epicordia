import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class CustomCircularCheckbox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback? onTap;
  final double size;
  final Color? activeColor;
  final Color? borderColor;
  final Color? checkColor;

  const CustomCircularCheckbox({
    super.key,
    required this.isChecked,
    this.onTap,
    this.size = 18.0,
    this.activeColor,
    this.borderColor,
    this.checkColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultActive = isDark ? EpicordiaColors.successDark : EpicordiaColors.successLight;
    final defaultBorder = isDark ? EpicordiaColors.borderStrongDark : EpicordiaColors.borderStrongLight;

    final fillClr = activeColor ?? defaultActive;
    final borderClr = borderColor ?? defaultBorder;
    final iconClr = checkColor ?? Colors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isChecked ? fillClr : Colors.transparent,
          border: Border.all(
            color: isChecked ? fillClr : borderClr,
            width: isChecked ? 1.5 : 1.6,
          ),
        ),
        child: isChecked
            ? Icon(
                Icons.check_rounded,
                size: size * 0.65,
                color: iconClr,
              )
            : null,
      ),
    );
  }
}
