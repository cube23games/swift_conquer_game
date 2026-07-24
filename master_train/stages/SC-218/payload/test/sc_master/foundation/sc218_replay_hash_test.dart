import 'package:flutter_test/flutter_test.dart';
import 'package:swift_conquer_game/sc_master/core/replay/replay_event.dart';
import 'package:swift_conquer_game/sc_master/core/replay/replay_journal.dart';
import 'package:swift_conquer_game/sc_master/core/replay/state_hasher.dart';

void main() {
  test('SC-218 equal replay data hashes equally', () {
    final journal = ReplayJournal()
      ..record(const ReplayEvent(tick: 1, type: 'spawn'));
    final hasher = StateHasher();
    expect(hasher.hashJson(journal.encode()), hasher.hashJson(journal.encode()));
  });
}
