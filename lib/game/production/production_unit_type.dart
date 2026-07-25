import '../buildings/building_type.dart';

enum ProductionUnitType {
  rifleInfantry,
  harvester,
  tank,
}

extension ProductionUnitTypeX on ProductionUnitType {
  String get label {
    switch (this) {
      case ProductionUnitType.rifleInfantry:
        return 'Rifle Infantry';
      case ProductionUnitType.harvester:
        return 'Harvester';
      case ProductionUnitType.tank:
        return 'Tank';
    }
  }

  String get shortLabel {
    switch (this) {
      case ProductionUnitType.rifleInfantry:
        return 'INF';
      case ProductionUnitType.harvester:
        return 'HARV';
      case ProductionUnitType.tank:
        return 'TANK';
    }
  }

  BuildingType get producer {
    switch (this) {
      case ProductionUnitType.rifleInfantry:
        return BuildingType.barracks;
      case ProductionUnitType.harvester:
        return BuildingType.refinery;
      case ProductionUnitType.tank:
        return BuildingType.warFactory;
    }
  }

  String get unitKind {
    switch (this) {
      case ProductionUnitType.rifleInfantry:
        return 'infantry';
      case ProductionUnitType.harvester:
        return 'harvester';
      case ProductionUnitType.tank:
        return 'tank';
    }
  }

  int get hp {
    switch (this) {
      case ProductionUnitType.rifleInfantry:
        return 30;
      case ProductionUnitType.harvester:
        return 80;
      case ProductionUnitType.tank:
        return 120;
    }
  }

  double get prototypeBuildSeconds {
    switch (this) {
      case ProductionUnitType.rifleInfantry:
        return 3;
      case ProductionUnitType.harvester:
        return 5;
      case ProductionUnitType.tank:
        return 6;
    }
  }
}
