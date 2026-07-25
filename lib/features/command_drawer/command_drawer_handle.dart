import 'package:flutter/material.dart';

class CommandDrawerHandle extends StatelessWidget {
  const CommandDrawerHandle({
    super.key,
    required this.open,
    required this.onPressed,
  });

  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF162238),
      elevation: 8,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
      child: InkWell(
        key: const ValueKey('command-drawer-handle'),
        onTap: onPressed,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
        child: SizedBox(
          width: 50,
          height: 88,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                open ? Icons.chevron_right : Icons.chevron_left,
                color: const Color(0xFFF3C623),
              ),
              const SizedBox(height: 4),
              const RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'COMMAND',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
