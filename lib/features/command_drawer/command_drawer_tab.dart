enum CommandDrawerTab {
  structures,
  infantry,
  vehicles,
  tactical,
}

extension CommandDrawerTabX on CommandDrawerTab {
  String get label {
    switch (this) {
      case CommandDrawerTab.structures:
        return 'Structures';
      case CommandDrawerTab.infantry:
        return 'Infantry';
      case CommandDrawerTab.vehicles:
        return 'Vehicles';
      case CommandDrawerTab.tactical:
        return 'Tactical';
    }
  }
}
