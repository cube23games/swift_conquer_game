import 'package:flutter/material.dart';

class ProductionSection extends StatelessWidget {
  const ProductionSection({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
    this.enabled = true,
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      color: const Color(0xFF152238),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey('production-section-$title'),
        initiallyExpanded: initiallyExpanded,
        enabled: enabled,
        maintainState: true,
        leading: Icon(icon, color: enabled ? Colors.white70 : Colors.white30),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white38,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: enabled ? Colors.white54 : Colors.white30,
            fontSize: 11,
          ),
        ),
        children: <Widget>[child],
      ),
    );
  }
}
