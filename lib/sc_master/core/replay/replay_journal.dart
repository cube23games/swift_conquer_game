import 'dart:convert';
import 'replay_event.dart';

final class ReplayJournal {
  final List<ReplayEvent> _events = [];

  void record(ReplayEvent event) => _events.add(event);

  List<ReplayEvent> get events => List.unmodifiable(_events);

  String encode() {
    return jsonEncode(_events.map((event) => event.toJson()).toList());
  }
}
