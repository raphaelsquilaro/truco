import '../models/card_model.dart';
import '../models/game_state_model.dart';
import '../models/player_model.dart';
import '../models/round_model.dart';
import '../models/truco_enums.dart';
import 'truco_deck.dart';
import 'truco_rules.dart';

class TrucoEngine {
  /// Initializes and starts a new match
  static GameStateModel startMatch(GameStateModel state) {
    if (state.players.length < state.mode.maxPlayers) {
      throw Exception('Número insuficiente de jogadores para iniciar a partida.');
    }

    // Automatically configure teams based on alternating seats
    final updatedPlayers = <PlayerModel>[];
    for (int i = 0; i < state.players.length; i++) {
      final p = state.players[i];
      final team = TrucoRules.getTeamForSeat(i, state.mode);
      updatedPlayers.add(p.copyWith(
        seatIndex: i,
        team: team,
        hand: [],
      ));
    }

    final newState = state.copyWith(
      players: updatedPlayers,
      scoreTeamA: 0,
      scoreTeamB: 0,
      currentDealerIndex: 0,
      status: GameStatus.playing,
      lastMessage: 'Partida iniciada! Embaralhando as cartas...',
    );

    return dealNewHand(newState, dealerIndex: 0);
  }

  /// Deals a new hand to players
  static GameStateModel dealNewHand(GameStateModel state, {int? dealerIndex}) {
    final playerCount = state.players.length;
    final int dealer = dealerIndex ?? ((state.currentDealerIndex + 1) % playerCount);
    final int starter = (dealer + 1) % playerCount;

    final deck = TrucoDeck.shuffleDeck();
    int deckPointer = 0;

    // Deal 3 cards to each player
    final updatedPlayers = <PlayerModel>[];
    for (int i = 0; i < playerCount; i++) {
      final cards = deck.sublist(deckPointer, deckPointer + 3);
      deckPointer += 3;
      updatedPlayers.add(state.players[i].copyWith(hand: cards));
    }

    // Vira card (for Paulista)
    CardModel? vira;
    if (state.variant == TrucoVariant.paulista) {
      vira = deck[deckPointer++];
    }

    // Check Special Hand (Mão de 11 no Paulista, Mão de 10 no Mineiro)
    final threshold = state.variant.specialHandScoreThreshold;
    bool isSpecial = false;
    Team? specialTeam;

    if (state.scoreTeamA == threshold && state.scoreTeamB == threshold) {
      // Mão de Ferro! Ambas equipes empatadas na mão decisiva
      isSpecial = true;
      specialTeam = null; // Mão de ferro joga no escuro
    } else if (state.scoreTeamA == threshold) {
      isSpecial = true;
      specialTeam = Team.teamA;
    } else if (state.scoreTeamB == threshold) {
      isSpecial = true;
      specialTeam = Team.teamB;
    }

    final int initialHandPoints = state.variant.initialPoints;
    final starterPlayer = updatedPlayers[starter];

    String message = 'Nova mão valendo $initialHandPoints ponto(s). Vez de ${starterPlayer.name}.';
    if (isSpecial) {
      if (specialTeam != null) {
        message = '${specialTeam.label} está na ${state.variant == TrucoVariant.paulista ? "Mão de 11" : "Mão de 10"}! Decidindo se joga...';
      } else {
        message = 'Mão de Ferro! Ambas as equipes com $threshold pontos. Jogada no escuro!';
      }
    }

    return state.copyWith(
      players: updatedPlayers,
      currentDealerIndex: dealer,
      currentTurnPlayerIndex: starter,
      handRoundStarterPlayerIndex: starter,
      handPoints: initialHandPoints,
      trucoState: TrucoCallState.none,
      trucoProposerTeam: null,
      trucoProposerPlayerId: null,
      pendingTrucoValue: 0,
      vira: vira,
      rounds: [const RoundModel(roundIndex: 0)],
      currentRoundIndex: 0,
      handWinner: null,
      isSpecialHand: isSpecial,
      specialHandTeam: specialTeam,
      specialHandAccepted: isSpecial && specialTeam == null ? true : null,
      status: GameStatus.playing,
      lastMessage: message,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Plays a card from the current turn player
  static GameStateModel playCard(
    GameStateModel state,
    String playerId,
    CardModel card, {
    bool isFaceDown = false,
  }) {
    if (state.status != GameStatus.playing) return state;
    if (state.trucoState.isPending) return state; // Must resolve truco call first

    final currentTurnPlayer = state.currentTurnPlayer;
    if (currentTurnPlayer == null || currentTurnPlayer.id != playerId) {
      return state; // Not player's turn
    }

    // Rules: Cannot play face down in the 1st round of a hand
    final effectiveFaceDown = state.currentRoundIndex == 0 ? false : isFaceDown;

    // Remove card from hand
    final newHand = List<CardModel>.from(currentTurnPlayer.hand)
      ..removeWhere((c) => c.rank == card.rank && c.suit == card.suit);

    final playedCard = PlayedCard(
      playerId: currentTurnPlayer.id,
      playerName: currentTurnPlayer.name,
      seatIndex: currentTurnPlayer.seatIndex,
      team: currentTurnPlayer.team,
      card: card.copyWith(isFaceDown: effectiveFaceDown),
      isFaceDown: effectiveFaceDown,
    );

    final updatedPlayers = state.players.map((p) {
      if (p.id == playerId) {
        return p.copyWith(hand: newHand);
      }
      return p;
    }).toList();

    final currentRound = state.currentRound;
    final updatedRoundPlayedCards = List<PlayedCard>.from(currentRound.playedCards)
      ..add(playedCard);

    final playerCount = state.players.length;

    // Check if round is finished (all players played a card)
    if (updatedRoundPlayedCards.length < playerCount) {
      // Advance to next player
      final nextTurn = (state.currentTurnPlayerIndex + 1) % playerCount;
      final nextPlayer = updatedPlayers[nextTurn];

      final updatedRound = currentRound.copyWith(playedCards: updatedRoundPlayedCards);
      final updatedRounds = List<RoundModel>.from(state.rounds);
      updatedRounds[state.currentRoundIndex] = updatedRound;

      final cardDesc = effectiveFaceDown ? 'uma carta coberta' : card.displayName;
      return state.copyWith(
        players: updatedPlayers,
        rounds: updatedRounds,
        currentTurnPlayerIndex: nextTurn,
        lastMessage: '${currentTurnPlayer.name} jogou $cardDesc. Vez de ${nextPlayer.name}.',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    // All players have played their card for this round! Evaluate trick winner
    final roundEval = TrucoRules.evaluateRoundWinner(
      updatedRoundPlayedCards,
      state.variant,
      vira: state.vira,
    );

    final finishedRound = currentRound.copyWith(
      playedCards: updatedRoundPlayedCards,
      winnerTeam: roundEval.winnerTeam,
      winningPlayerId: roundEval.winningPlayerId,
      winningCard: roundEval.winningCard,
      isTied: roundEval.isTied,
    );

    final updatedRounds = List<RoundModel>.from(state.rounds);
    updatedRounds[state.currentRoundIndex] = finishedRound;

    // Check if overall Hand is decided
    final winPlayer = roundEval.winningPlayerId != null
        ? updatedPlayers.firstWhere(
            (p) => p.id == roundEval.winningPlayerId,
            orElse: () => updatedPlayers[state.handRoundStarterPlayerIndex],
          )
        : null;

    final handWinner = TrucoRules.evaluateHandWinner(updatedRounds);

    if (handWinner != null) {
      // Hand finished with a winner! Enter 5-second handFinished interval or matchFinished
      return _finishHand(
        state.copyWith(
          players: updatedPlayers,
          rounds: updatedRounds,
          roundWinnerTeam: roundEval.winnerTeam,
          roundWinningPlayerName: winPlayer?.name,
          roundWinningCard: roundEval.winningCard,
          isRoundTied: roundEval.isTied,
        ),
        handWinner,
        state.handPoints,
        '${handWinner.label} venceu a mão e faturou ${state.handPoints} ponto(s)!',
      );
    }

    // Check if 3 rounds completed and it resulted in a complete tie
    if (updatedRounds.length == 3 && finishedRound.isTied && updatedRounds[0].isTied && updatedRounds[1].isTied) {
      // Complete tie across all 3 rounds: no points awarded, 5-second interval before new hand
      return state.copyWith(
        players: updatedPlayers,
        rounds: updatedRounds,
        status: GameStatus.handFinished,
        intervalExpiresAt: DateTime.now().millisecondsSinceEpoch + 5000,
        isRoundTied: true,
        lastMessage: 'Empatou as três rodadas! Nenhum time pontua. Nova mão em 5s...',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    // Hand continues to next round with 5-second interval
    final nextRoundIndex = state.currentRoundIndex + 1;
    if (nextRoundIndex < 3) {
      int nextStarterIndex = state.handRoundStarterPlayerIndex;
      if (winPlayer != null) {
        nextStarterIndex = winPlayer.seatIndex;
      }

      final nextStarter = updatedPlayers[nextStarterIndex];
      final roundOutcome = roundEval.isTied
          ? 'Rodada empatou (canguera)!'
          : '${roundEval.winnerTeam!.label} fez a rodada $nextRoundIndex!';

      return state.copyWith(
        players: updatedPlayers,
        rounds: updatedRounds,
        status: GameStatus.roundFinished,
        roundWinnerTeam: roundEval.winnerTeam,
        roundWinningPlayerName: winPlayer?.name,
        roundWinningCard: roundEval.winningCard,
        isRoundTied: roundEval.isTied,
        nextRoundIndex: nextRoundIndex,
        nextStarterPlayerName: nextStarter.name,
        handRoundStarterPlayerIndex: nextStarterIndex,
        currentTurnPlayerIndex: nextStarterIndex,
        intervalExpiresAt: DateTime.now().millisecondsSinceEpoch + 5000,
        lastMessage: '$roundOutcome Destaque para a ${nextRoundIndex + 1}ª rodada em 5s...',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    // Fallback if 3 rounds passed without winner
    return state.copyWith(
      players: updatedPlayers,
      rounds: updatedRounds,
      status: GameStatus.handFinished,
      intervalExpiresAt: DateTime.now().millisecondsSinceEpoch + 5000,
      lastMessage: 'Fim da mão sem pontuação.',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Player calls Truco, Seis, Nove, or Doze
  static GameStateModel callTruco(GameStateModel state, String playerId) {
    if (state.status != GameStatus.playing) return state;
    if (state.trucoState.isPending) return state;

    final player = state.getPlayerById(playerId);
    if (player == null) return state;

    // Special hand rule: Truco cannot be called in Mão de 11 / Mão de 10
    if (state.isSpecialHand) return state;

    // Team that proposed last cannot re-propose before opponent raises
    if (state.trucoProposerTeam == player.team && state.trucoState == TrucoCallState.accepted) {
      return state;
    }

    final nextPoints = TrucoRules.getNextRaisePoints(state.handPoints, state.variant);
    final callState = _getCallStateForPoints(nextPoints);
    final callLabel = TrucoRules.getRaiseActionLabel(nextPoints);

    return state.copyWith(
      trucoState: callState,
      trucoProposerTeam: player.team,
      trucoProposerPlayerId: playerId,
      pendingTrucoValue: nextPoints,
      lastMessage: '${player.name} (${player.team.label}) gritou $callLabel!',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Responds to a pending Truco call
  static GameStateModel respondToTruco(
    GameStateModel state,
    String respondingPlayerId, {
    required bool accept,
    bool raiseInstead = false,
  }) {
    if (!state.trucoState.isPending) return state;

    final responder = state.getPlayerById(respondingPlayerId);
    if (responder == null) return state;

    // Only players from the opposing team can respond
    if (responder.team == state.trucoProposerTeam) return state;

    if (raiseInstead) {
      // Opposing team raises the stake even higher!
      final nextPoints = TrucoRules.getNextRaisePoints(state.pendingTrucoValue, state.variant);
      final nextCallState = _getCallStateForPoints(nextPoints);
      final label = TrucoRules.getRaiseActionLabel(nextPoints);

      return state.copyWith(
        trucoState: nextCallState,
        trucoProposerTeam: responder.team,
        trucoProposerPlayerId: respondingPlayerId,
        pendingTrucoValue: nextPoints,
        lastMessage: '${responder.name} pediu $label!',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    if (accept) {
      // Accepted! Hand points are updated to the called value
      final newPoints = state.pendingTrucoValue;
      return state.copyWith(
        handPoints: newPoints,
        trucoState: TrucoCallState.accepted,
        lastMessage: '${responder.name} aceitou! A mão agora vale $newPoints ponto(s).',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      // Refused! Proposing team wins immediately
      final winnerTeam = state.trucoProposerTeam!;
      final pointsAwarded = TrucoRules.getPointsOnRefusal(
        state.handPoints,
        state.pendingTrucoValue,
        state.variant,
      );

      return _finishHand(
        state,
        winnerTeam,
        pointsAwarded,
        '${responder.team.label} correu do truco! ${winnerTeam.label} ganha $pointsAwarded ponto(s).',
      );
    }
  }

  /// Decision for Mão de 11 (Paulista) or Mão de 10 (Mineiro)
  static GameStateModel respondSpecialHand(
    GameStateModel state,
    String playerId,
    bool accept,
  ) {
    if (!state.isSpecialHand || state.specialHandTeam == null) return state;

    final player = state.getPlayerById(playerId);
    if (player == null || player.team != state.specialHandTeam) return state;

    if (accept) {
      // Play hand for 3 points (or 4 in Mineiro)
      final points = state.variant == TrucoVariant.paulista ? 3 : 4;
      return state.copyWith(
        handPoints: points,
        specialHandAccepted: true,
        lastMessage: '${player.team.label} aceitou jogar a mão valendo $points pontos!',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      // Correr na mão de 11: oponente ganha 1 ponto (ou 2 no Mineiro)
      final opponent = state.specialHandTeam!.opponent;
      final points = state.variant == TrucoVariant.paulista ? 1 : 2;

      return _finishHand(
        state,
        opponent,
        points,
        '${player.team.label} correu da Mão Especial. ${opponent.label} ganha $points ponto(s).',
      );
    }
  }

  /// Finalizes the current hand, awards points, and checks match conclusion
  static GameStateModel _finishHand(
    GameStateModel state,
    Team winnerTeam,
    int points,
    String message,
  ) {
    int newScoreA = state.scoreTeamA;
    int newScoreB = state.scoreTeamB;

    if (winnerTeam == Team.teamA) {
      newScoreA += points;
    } else {
      newScoreB += points;
    }

    final target = state.variant.targetScore;
    if (newScoreA >= target) {
      return state.copyWith(
        scoreTeamA: newScoreA,
        scoreTeamB: newScoreB,
        handWinner: winnerTeam,
        matchWinner: Team.teamA,
        status: GameStatus.matchFinished,
        lastMessage: 'PARABÉNS! TIME A É O CAMPEÃO DO TRUCO ($newScoreA x $newScoreB)!',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } else if (newScoreB >= target) {
      return state.copyWith(
        scoreTeamA: newScoreA,
        scoreTeamB: newScoreB,
        handWinner: winnerTeam,
        matchWinner: Team.teamB,
        status: GameStatus.matchFinished,
        lastMessage: 'PARABÉNS! TIME B É O CAMPEÃO DO TRUCO ($newScoreB x $newScoreA)!',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    // Enter 5-second handFinished interval before dealing next hand
    final nextDealer = (state.currentDealerIndex + 1) % state.players.length;
    final nextStarter = state.players[(nextDealer + 1) % state.players.length];

    return state.copyWith(
      scoreTeamA: newScoreA,
      scoreTeamB: newScoreB,
      handWinner: winnerTeam,
      roundWinnerTeam: winnerTeam,
      status: GameStatus.handFinished,
      intervalExpiresAt: DateTime.now().millisecondsSinceEpoch + 5000,
      nextRoundIndex: 0,
      nextStarterPlayerName: nextStarter.name,
      lastMessage: '$message Próxima mão em 5s...',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Advances game state after the 5-second interval expires
  static GameStateModel advanceAfterInterval(GameStateModel state) {
    if (state.status == GameStatus.roundFinished) {
      final nextIndex = state.nextRoundIndex;
      final updatedRounds = List<RoundModel>.from(state.rounds);
      if (updatedRounds.length <= nextIndex) {
        updatedRounds.add(RoundModel(roundIndex: nextIndex));
      }

      final starter = state.players[state.handRoundStarterPlayerIndex];

      return state.copyWith(
        rounds: updatedRounds,
        currentRoundIndex: nextIndex,
        currentTurnPlayerIndex: state.handRoundStarterPlayerIndex,
        status: GameStatus.playing,
        intervalExpiresAt: 0,
        lastMessage: 'Rodada ${nextIndex + 1} iniciada! Vez de ${starter.name}.',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    } else if (state.status == GameStatus.handFinished) {
      return dealNewHand(
        state.copyWith(
          intervalExpiresAt: 0,
        ),
      );
    }
    return state;
  }

  static TrucoCallState _getCallStateForPoints(int points) {
    switch (points) {
      case 3:
      case 4:
        return TrucoCallState.trucoPending;
      case 6:
      case 8:
        return TrucoCallState.seisPending;
      case 9:
        return TrucoCallState.novePending;
      case 12:
        return TrucoCallState.dozePending;
      default:
        return TrucoCallState.trucoPending;
    }
  }
}

