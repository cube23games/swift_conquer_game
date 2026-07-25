import 'package:flutter/material.dart';

class ProductionTile extends StatelessWidget {
  const ProductionTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.selected = false,
    this.enabled = true,
    this.onPressed,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? const Color(0xFFF3C623)
        : const Color(0xFF31435B);
    final foreground = enabled ? Colors.white : Colors.white38;

    return Material(
      color: const Color(0xFF182337),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        key: ValueKey('production-$title'),
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 26),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled ? Colors.white60 : Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
