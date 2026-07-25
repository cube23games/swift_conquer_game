import 'package:flutter/material.dart';

class CommandBarAction {
  const CommandBarAction({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;
}

class ContextCommandBar extends StatelessWidget {
  const ContextCommandBar({
    super.key,
    required this.selectionCount,
    required this.actions,
  });

  final int selectionCount;
  final List<CommandBarAction> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Material(
        key: const ValueKey('context-command-bar'),
        color: const Color(0xEE101A2C),
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  selectionCount == 0
                      ? 'No selection'
                      : '$selectionCount selected',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: actions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return action.primary
                        ? ElevatedButton(
                            onPressed: action.onPressed,
                            child: Text(action.label),
                          )
                        : OutlinedButton(
                            onPressed: action.onPressed,
                            child: Text(action.label),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
