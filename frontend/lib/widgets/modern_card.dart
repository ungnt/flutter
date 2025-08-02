import 'package:flutter/material.dart';
import 'package:motouber/theme/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final double elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool useGradient;

  const ModernCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.gradient,
    this.padding,
    this.elevation = 8,
    this.onTap,
    this.borderRadius,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: useGradient 
            ? (gradient ?? AppTheme.primaryGradient)
            : null,
        color: useGradient 
            ? null 
            : (backgroundColor ?? (isDark ? AppTheme.darkColor : Colors.white)),
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: isDark && !useGradient
            ? Border.all(color: AppTheme.chromeColor.withOpacity(0.2))
            : null,
        boxShadow: [
          BoxShadow(
            color: useGradient 
                ? AppTheme.primaryColor.withOpacity(0.3)
                : (isDark 
                    ? AppTheme.secondaryColor.withOpacity(0.2)
                    : AppTheme.primaryColor.withOpacity(0.1)),
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: content,
      );
    }

    return content;
  }
}

// GlowingCard movido para widgets/glowing_card.dart para evitar duplicação