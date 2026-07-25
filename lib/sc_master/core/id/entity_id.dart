final class EntityId implements Comparable<EntityId> {
  final int value;

  const EntityId(this.value) : assert(value > 0);

  @override
  int compareTo(EntityId other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) {
    return other is EntityId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'E$value';
}
