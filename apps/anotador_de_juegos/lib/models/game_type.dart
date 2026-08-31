enum GameType {
  custom,
  truco,
  generala,
  chinchon,
  uno,
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
      case GameType.chinchon:
        return 'Chinchón';
      case GameType.uno:
        return 'Uno / Rummy';
      case GameType.burako:
        return 'Burako / Canasta';
      case GameType.escoba:
        return 'Escoba de 15';
    }
  }

  String get description {
    switch (this) {
      case GameType.custom:
        return 'De 1 a 12 jugadores o equipos con sumas rápidas';
      case GameType.truco:
        return '15, 24 o 30 pts con fósforos tradicionales o números gigantes';
      case GameType.generala:
        return 'Planilla oficial con cálculo automático de categorías y servidas';
      case GameType.chinchon:
        return 'Rondas acumulativas, límite de eliminación y reenganche';
      case GameType.uno:
        return 'Conteo de cartas en mano por rondas y límite de puntos';
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
      case GameType.chinchon:
        return 'view_carousel';
      case GameType.uno:
        return 'filter_none';
      case GameType.burako:
        return 'grid_view';
      case GameType.escoba:
        return 'cleaning_services';
    }
  }
}
