enum GameMode {
  twoPlayers,
  fourPlayers,
  sixPlayers;

  int get maxPlayers {
    switch (this) {
      case GameMode.twoPlayers:
        return 2;
      case GameMode.fourPlayers:
        return 4;
      case GameMode.sixPlayers:
        return 6;
    }
  }

  String get label {
    switch (this) {
      case GameMode.twoPlayers:
        return '2 Jogadores (1x1)';
      case GameMode.fourPlayers:
        return '4 Jogadores (2x2)';
      case GameMode.sixPlayers:
        return '6 Jogadores (3x3)';
    }
  }

  String get shortLabel {
    switch (this) {
      case GameMode.twoPlayers:
        return '1x1';
      case GameMode.fourPlayers:
        return '2x2';
      case GameMode.sixPlayers:
        return '3x3';
    }
  }
}

enum TrucoVariant {
  paulista,
  mineiro;

  String get label {
    switch (this) {
      case TrucoVariant.paulista:
        return 'Truco Paulista';
      case TrucoVariant.mineiro:
        return 'Truco Mineiro';
    }
  }

  String get description {
    switch (this) {
      case TrucoVariant.paulista:
        return 'Vira define a manilha (a carta logo acima). Manilhas desempatam por naipe: Paus > Copas > Espadas > Ouros.';
      case TrucoVariant.mineiro:
        return 'Manilhas fixas (Manilhas Velhas): Zap (4♣), 7 Copas (7♥), Espadilha (A♠), Picafumo (7♦).';
    }
  }

  int get initialPoints {
    switch (this) {
      case TrucoVariant.paulista:
        return 1;
      case TrucoVariant.mineiro:
        return 2;
    }
  }

  int get targetScore => 12;

  int get specialHandScoreThreshold {
    switch (this) {
      case TrucoVariant.paulista:
        return 11; // Mão de 11
      case TrucoVariant.mineiro:
        return 10; // Mão de 10
    }
  }
}

enum Team {
  teamA,
  teamB;

  String get label {
    switch (this) {
      case Team.teamA:
        return 'Time A';
      case Team.teamB:
        return 'Time B';
    }
  }

  Team get opponent {
    return this == Team.teamA ? Team.teamB : Team.teamA;
  }
}

enum TrucoCallState {
  none,
  trucoPending,    // Truco pedido, aguardando resposta
  seisPending,     // Seis pedido
  novePending,     // Nove pedido
  dozePending,     // Doze pedido
  accepted,
  refused;

  bool get isPending =>
      this == TrucoCallState.trucoPending ||
      this == TrucoCallState.seisPending ||
      this == TrucoCallState.novePending ||
      this == TrucoCallState.dozePending;
}

enum GameStatus {
  waitingForPlayers,
  readyToStart,
  playing,
  roundFinished,
  handFinished,
  matchFinished,
}

extension GameStatusX on GameStatus {
  bool get isInterval =>
      this == GameStatus.roundFinished || this == GameStatus.handFinished;
}

