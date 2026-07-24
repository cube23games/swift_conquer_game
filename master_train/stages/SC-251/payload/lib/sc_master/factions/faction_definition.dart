import 'faction_id.dart';

final class FactionDefinition {
  final FactionId id;
  final String displayName;
  final bool canonicalDataPending;

  const FactionDefinition({
    required this.id,
    required this.displayName,
    this.canonicalDataPending = true,
  });
}
