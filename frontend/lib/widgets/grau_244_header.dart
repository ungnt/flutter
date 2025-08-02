import 'package:flutter/material.dart';
import 'package:motouber/theme/app_theme.dart';

class Grau244Header extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const Grau244Header({
    super.key,
    required this.title,
    this.subtitle = '',
    this.action,
  });

  @override
  State<Grau244Header> createState() => _Grau244HeaderState();
}

class _Grau244HeaderState extends State<Grau244Header>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Background gradient container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isDark 
                  ? LinearGradient(
                      colors: [
                        AppTheme.darkColor,
                        AppTheme.darkColor.withOpacity(0.8),
                        AppTheme.chromeColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              border: isDark 
                  ? Border.all(color: AppTheme.chromeColor.withOpacity(0.3))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Motorcycle icon with glow effect
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: isDark 
                            ? Border.all(color: AppTheme.chromeColor.withOpacity(0.3))
                            : null,
                      ),
                      child: Icon(
                        Icons.motorcycle,
                        color: isDark ? AppTheme.accentColor : Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.accentColor : Colors.white,
                              shadows: isDark ? null : [
                                const Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          if (widget.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark 
                                    ? AppTheme.chromeColor 
                                    : Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.action != null) widget.action!,
                  ],
                ),
              ],
            ),
          ),
          
          // Shimmer effect overlay
          AnimatedBuilder(
            animation: _shimmerAnimation,
            builder: (context, child) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(_shimmerAnimation.value, -1),
                      end: Alignment(_shimmerAnimation.value + 0.5, 1),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MotorcycleStatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final IconData icon;

  const MotorcycleStatusBadge({
    super.key,
    required this.status,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}