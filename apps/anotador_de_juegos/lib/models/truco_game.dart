class TrucoScoreStep {
  final int teamIndex; // 0 o 1
  final int points;
  final String label;
  final DateTime timestamp;

  TrucoScoreStep({
    required this.teamIndex,
    required this.points,
    required this.label,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'teamIndex': teamIndex,
        'points': points,
        'label': label,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TrucoScoreStep.fromJson(Map<String, dynamic> json) => TrucoScoreStep(
        teamIndex: json['teamIndex'] as int,
        points: json['points'] as int,
        label: json['label'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class TrucoGame {
  String team1Name;
  String team2Name;
  int team1Score;
  int team2Score;
  int targetPoints; // 15, 24, 30
  List<TrucoScoreStep> history;
  bool isFinished;
  String? winnerName;

  TrucoGame({
    this.team1Name = 'Nosotros',
    this.team2Name = 'Ellos',
    this.team1Score = 0,
    this.team2Score = 0,
    this.targetPoints = 30,
    List<TrucoScoreStep>? history,
    this.isFinished = false,
    this.winnerName,
  }) : history = history ?? [];

  int get halfTarget => targetPoints ~/ 2;

  bool isBuenas(int score) {
    if (targetPoints == 15) return true;
    return score > halfTarget;
  }

  int getDisplayScore(int score) {
    if (targetPoints == 15) return score;
    if (score <= halfTarget) {
      return score; // Malas
    } else {
      return score - halfTarget; // Buenas
    }
  }

  String getScoreLabel(int score) {
    if (targetPoints == 15) return '$score pts';
    if (score <= halfTarget) {
      return '$score a las Malas';
    } else {
      return '${score - halfTarget} a las Buenas';
    }
  }

  void addPoints(int teamIndex, int points, {String label = '+pts'}) {
    if (isFinished) return;

    if (teamIndex == 0) {
      team1Score = (team1Score + points).clamp(0, targetPoints);
      history.add(TrucoScoreStep(
        teamIndex: 0,
        points: points,
        label: label,
        timestamp: DateTime.now(),
      ));
      if (team1Score >= targetPoints) {
        isFinished = true;
        winnerName = team1Name;
      }
    } else {
      team2Score = (team2Score + points).clamp(0, targetPoints);
      history.add(TrucoScoreStep(
        teamIndex: 1,
        points: points,
        label: label,
        timestamp: DateTime.now(),
      ));
      if (team2Score >= targetPoints) {
        isFinished = true;
        winnerName = team2Name;
      }
    }
  }

  void subtractPoint(int teamIndex) {
    if (teamIndex == 0 && team1Score > 0) {
      team1Score--;
      history.add(TrucoScoreStep(
        teamIndex: 0,
        points: -1,
        label: '-1',
        timestamp: DateTime.now(),
      ));
      isFinished = false;
      winnerName = null;
    } else if (teamIndex == 1 && team2Score > 0) {
      team2Score--;
      history.add(TrucoScoreStep(
        teamIndex: 1,
        points: -1,
        label: '-1',
        timestamp: DateTime.now(),
      ));
      isFinished = false;
      winnerName = null;
    }
  }

  bool undo() {
    if (history.isEmpty) return false;
    final last = history.removeLast();
    if (last.teamIndex == 0) {
      team1Score = (team1Score - last.points).clamp(0, targetPoints);
    } else {
      team2Score = (team2Score - last.points).clamp(0, targetPoints);
    }
    isFinished = false;
    winnerName = null;
    return true;
  }

  void reset() {
    team1Score = 0;
    team2Score = 0;
    history.clear();
    isFinished = false;
    winnerName = null;
  }

  int getFaltaEnvidoPoints(int callingTeam) {
    // Si van en las malas, son los puntos para ganar el partido
    // Si van en las buenas, son los puntos que le faltan al que va ganando
    final maxScore = team1Score > team2Score ? team1Score : team2Score;
    if (maxScore <= halfTarget && targetPoints > 15) {
      return targetPoints - maxScore;
    } else {
      return targetPoints - maxScore;
    }
  }

  Map<String, dynamic> toJson() => {
        'team1Name': team1Name,
        'team2Name': team2Name,
        'team1Score': team1Score,
        'team2Score': team2Score,
        'targetPoints': targetPoints,
        'history': history.map((e) => e.toJson()).toList(),
        'isFinished': isFinished,
        'winnerName': winnerName,
      };

  factory TrucoGame.fromJson(Map<String, dynamic> json) => TrucoGame(
        team1Name: json['team1Name'] as String? ?? 'Nosotros',
        team2Name: json['team2Name'] as String? ?? 'Ellos',
        team1Score: json['team1Score'] as int? ?? 0,
        team2Score: json['team2Score'] as int? ?? 0,
        targetPoints: json['targetPoints'] as int? ?? 30,
        history: (json['history'] as List<dynamic>?)
            ?.map((e) => TrucoScoreStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        isFinished: json['isFinished'] as bool? ?? false,
        winnerName: json['winnerName'] as String?,
      );
}
