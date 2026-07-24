abstract interface class GameCommand {
  int get tick;
  int get playerId;
  String get type;
  Map<String, Object?> toJson();
}
