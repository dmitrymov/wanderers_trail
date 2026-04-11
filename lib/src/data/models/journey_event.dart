import 'package:flutter/foundation.dart';

class JourneyEvent {
  final String title;
  final String description;
  final List<EventChoice> choices;

  const JourneyEvent({
    required this.title,
    required this.description,
    required this.choices,
  });
}

class EventChoice {
  final String label;
  final VoidCallback onChosen;

  const EventChoice({
    required this.label,
    required this.onChosen,
  });
}
