import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: margin,
      child: Padding(padding: padding ?? const EdgeInsets.all(12), child: child),
    );

    if (onTap != null) {
      card = InkWell(onTap: onTap, child: card);
    }

    return card;
  }
}
