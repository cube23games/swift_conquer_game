final class ReplayEvent {
  final int tick;
  final String type;
  final Map<String, Object?> payload;

  const ReplayEvent({
    required this.tick,
    required this.type,
    this.payload = const {},
  });

  Map<String, Object?> toJson() => {
        'tick': tick,
        'type': type,
        'payload': payload,
      };
}
