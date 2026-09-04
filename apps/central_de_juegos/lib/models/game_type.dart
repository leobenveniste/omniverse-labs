import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';

enum GameType {
  custom,
  truco,
  generala,
  diezMil,
  burako,
  escoba,
}

extension GameTypeExtension on GameType {
  String localizedName(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case GameType.custom:
        return l10n.t('gameCustom');
      case GameType.truco:
        return l10n.t('gameTruco');
      case GameType.generala:
        return l10n.t('gameGenerala');
      case GameType.diezMil:
        return l10n.t('gameDiezMil');
      case GameType.burako:
        return l10n.t('gameBurako');
      case GameType.escoba:
        return l10n.t('gameEscoba');
    }
  }

  String localizedDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case GameType.custom:
        return l10n.t('gameCustomDesc');
      case GameType.truco:
        return l10n.t('gameTrucoDesc');
      case GameType.generala:
        return l10n.t('gameGeneralaDesc');
      case GameType.diezMil:
        return l10n.t('gameDiezMilDesc');
      case GameType.burako:
        return l10n.t('gameBurakoDesc');
      case GameType.escoba:
        return l10n.t('gameEscobaDesc');
    }
  }

  String get displayName {
    switch (this) {
      case GameType.custom:
        return 'Contador Libre';
      case GameType.truco:
        return 'Truco';
      case GameType.generala:
        return 'Generala';
      case GameType.diezMil:
        return 'Diez Mil';
      case GameType.burako:
        return 'Burako';
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
      case GameType.diezMil:
        return 'Anotador oficial a 10.000 puntos con dados, entradas y calculadora de tiro';
      case GameType.burako:
        return 'Planilla de Base y Puntos con indicador de salida y meta a 3000';
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
      case GameType.diezMil:
        return 'casino_outlined';
      case GameType.burako:
        return 'grid_view';
      case GameType.escoba:
        return 'cleaning_services';
    }
  }
}
