enum GameType {
  custom,
  truco,
  generala,
  burako,
  escoba,
}

extension GameTypeExtension on GameType {
  String get displayName {
    switch (this) {
      case GameType.custom:
        return 'Contador Libre';
      case GameType.truco:
        return 'Truco';
      case GameType.generala:
        return 'Generala';
      case GameType.burako:
        return 'Burako / Canasta';
      case GameType.escoba:
        return 'Escoba del 15';
    }
  }

  String get description {
    switch (this) {
      case GameType.custom:
        return 'De 1 a 12 jugadores o equipos con sumas por toque y ajustes';
      case GameType.truco:
        return 'Anotador oficial a 30 puntos con fósforos o números';
      case GameType.generala:
        return 'Planilla oficial con cálculo automático de categorías y servidas';
      case GameType.burako:
        return 'Canastas puras/impuras, bases y fichas en mano';
      case GameType.escoba:
        return 'Escobas, 7 de oro, oros, setenta y cartas';
    }
  }

  String get iconName {
    switch (this) {
      case GameType.custom:
        return 'calculate';
      case GameType.truco:
        return 'style';
      case GameType.generala:
        return 'casino';
      case GameType.burako:
        return 'grid_view';
      case GameType.escoba:
        return 'cleaning_services';
    }
  }
}
