import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool enableHoverEffect;
  final Color? backgroundColor;
  final Border? customBorder;

  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.enableHoverEffect = false,
    this.backgroundColor,
    this.customBorder,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.customBorder ??
        Border.all(
          color: _isHovered && widget.enableHoverEffect
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.border,
          width: 1,
        );

    final boxDecoration = BoxDecoration(
      color: widget.backgroundColor ?? AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: border,
      boxShadow: _isHovered && widget.enableHoverEffect
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
    );

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title!, style: AppTextStyles.h4),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.subtitle!, style: AppTextStyles.bodySmall),
                    ],
                  ],
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),
        ],
        widget.child,
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: boxDecoration,
          child: Material(
            color: Colors.transparent,
            child: content,
          ),
        ),
      ),
    );
  }
}
