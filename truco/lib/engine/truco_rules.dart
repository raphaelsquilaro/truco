import '../models/card_model.dart';
import '../models/round_model.dart';
import '../models/truco_enums.dart';

class TrucoRules {
  /// Checks if a card is a manilha in Truco Paulista given the [vira]
  static bool isPaulistaManilha(CardModel card, CardModel vira) {
    return card.rank == vira.rank.nextInCycle;
  }

  /// Checks if a card is a manilha in Truco Mineiro (Manilhas Fixas)
  static bool isMineiroManilha(CardModel card) {
    if (card.rank == Rank.four && card.suit == Suit.paus) return true;      // Zap
    if (card.rank == Rank.seven && card.suit == Suit.copas) return true;    // 7 de Copas
    if (card.rank == Rank.ace && card.suit == Suit.espadas) return true;     // Espadilha
    if (card.rank == Rank.seven && card.suit == Suit.ouros) return true;    // Picafumo
    return false;
  }

  /// Returns the iconic Brazilian Truco title if the card is a Manilha (Zap, Copeta, Espadilha, Picafumo)
  static String? getManilhaName(CardModel card, TrucoVariant variant, {CardModel? vira}) {
    if (card.isFaceDown) return null;

    if (variant == TrucoVariant.paulista) {
      if (vira != null && isPaulistaManilha(card, vira)) {
        switch (card.suit) {
          case Suit.paus:
            return '⚡ ZAP! ⚡';
          case Suit.copas:
            return '🔥 COPETA! 🔥';
          case Suit.espadas:
            return '🗡️ ESPADILHA! 🗡️';
          case Suit.ouros:
            return '💎 PICAFUMO! 💎';
        }
      }
    } else {
      if (card.rank == Rank.four && card.suit == Suit.paus) {
        return '⚡ ZAP! ⚡';
      } else if (card.rank == Rank.seven && card.suit == Suit.copas) {
        return '🔥 7 DE COPAS! 🔥';
      } else if (card.rank == Rank.ace && card.suit == Suit.espadas) {
        return '🗡️ ESPADILHA! 🗡️';
      } else if (card.rank == Rank.seven && card.suit == Suit.ouros) {
        return '💎 PICAFUMO! 💎';
      }
    }
    return null;
  }

  /// Returns effective numerical power of a card for comparison.
  /// Face down cards return 0.
  /// Normal cards return 1..10.
  /// Manilhas return 1001..1004.
  static int getCardPower(CardModel card, TrucoVariant variant, {CardModel? vira}) {
    if (card.isFaceDown) return 0;

    switch (variant) {
      case TrucoVariant.paulista:
        if (vira != null && isPaulistaManilha(card, vira)) {
          // Manilhas are ranked by suit power: Paus > Copas > Espadas > Ouros
          return 1000 + card.suit.manilhaPower;
        }
        return card.rank.basePower;

      case TrucoVariant.mineiro:
        if (card.rank == Rank.four && card.suit == Suit.paus) {
          return 1004; // Zap
        } else if (card.rank == Rank.seven && card.suit == Suit.copas) {
          return 1003; // 7 de Copas
        } else if (card.rank == Rank.ace && card.suit == Suit.espadas) {
          return 1002; // Espadilha
        } else if (card.rank == Rank.seven && card.suit == Suit.ouros) {
          return 1001; // Picafumo
        }
        return card.rank.basePower;
    }
  }

  /// Evaluates the winner of a single trick/sub-round.
  /// Returns a record with winner team (or null if tie), winning player ID, and highest card.
  static ({Team? winnerTeam, String? winningPlayerId, CardModel? winningCard, bool isTied})
      evaluateRoundWinner(
    List<PlayedCard> playedCards,
    TrucoVariant variant, {
    CardModel? vira,
  }) {
    if (playedCards.isEmpty) {
      return (winnerTeam: null, winningPlayerId: null, winningCard: null, isTied: false);
    }

    int highestPower = -1;
    final List<PlayedCard> highestCards = [];

    for (final played in playedCards) {
      final power = getCardPower(played.card, variant, vira: vira);
      if (power > highestPower) {
        highestPower = power;
        highestCards.clear();
        highestCards.add(played);
      } else if (power == highestPower) {
        highestCards.add(played);
      }
    }

    // Check if the highest cards are from opposing teams (Canguera / Empate)
    final teamsWithHighest = highestCards.map((c) => c.team).toSet();
    if (teamsWithHighest.length > 1) {
      // Tied between opposing teams!
      return (
        winnerTeam: null,
        winningPlayerId: null,
        winningCard: highestCards.first.card,
        isTied: true,
      );
    } else {
      // One team has the highest card (or teammates tied each other)
      final winner = highestCards.first;
      return (
        winnerTeam: winner.team,
        winningPlayerId: winner.playerId,
        winningCard: winner.card,
        isTied: false,
      );
    }
  }

  /// Determines the winner of the overall Hand (best of 3 rounds), or null if ongoing.
  static Team? evaluateHandWinner(List<RoundModel> rounds) {
    if (rounds.isEmpty) return null;

    final round1 = rounds.isNotEmpty ? rounds[0] : null;
    final round2 = rounds.length > 1 ? rounds[1] : null;
    final round3 = rounds.length > 2 ? rounds[2] : null;

    // Count direct wins
    int teamAWins = 0;
    int teamBWins = 0;
    for (final r in rounds) {
      if (r.winnerTeam == Team.teamA) teamAWins++;
      if (r.winnerTeam == Team.teamB) teamBWins++;
    }

    // A team with 2 wins always wins the hand
    if (teamAWins >= 2) return Team.teamA;
    if (teamBWins >= 2) return Team.teamB;

    // Check tie rules (canguera)
    if (round1 != null && round1.isTied) {
      // 1st round was tied:
      if (round2 != null) {
        if (round2.winnerTeam != null) {
          // Winner of 2nd round wins the hand!
          return round2.winnerTeam;
        } else if (round2.isTied && round3 != null) {
          // Both 1st and 2nd tied: winner of 3rd wins!
          if (round3.winnerTeam != null) {
            return round3.winnerTeam;
          } else if (round3.isTied) {
            // All 3 tied: Nobody wins points
            return null;
          }
        }
      }
      return null; // Hand still in progress
    }

    // 1st round was NOT tied:
    if (round1 != null && round1.winnerTeam != null) {
      final round1Winner = round1.winnerTeam!;

      // If 2nd round was tied: whoever won 1st wins immediately!
      if (round2 != null && round2.isTied) {
        return round1Winner;
      }

      // If 1st won by Team X, 2nd won by Team Y:
      if (round2 != null && round2.winnerTeam != null && round2.winnerTeam != round1Winner) {
        if (round3 != null) {
          if (round3.winnerTeam != null) {
            return round3.winnerTeam;
          } else if (round3.isTied) {
            // 3rd round tied: winner of 1st round wins!
            return round1Winner;
          }
        }
      }
    }

    return null;
  }

  /// Calculates points progression for Truco stakes.
  static int getNextRaisePoints(int currentPoints, TrucoVariant variant) {
    switch (variant) {
      case TrucoVariant.paulista:
        if (currentPoints < 3) return 3;
        if (currentPoints < 6) return 6;
        if (currentPoints < 9) return 9;
        return 12;

      case TrucoVariant.mineiro:
        if (currentPoints < 4) return 4;
        if (currentPoints < 8) return 8;
        return 12;
    }
  }

  /// Calculates points awarded to the prompter if the opponent runs (recusa).
  static int getPointsOnRefusal(int currentHandPoints, int proposedPoints, TrucoVariant variant) {
    // If opponents refuse the raise, the proposing team wins the points that the hand was worth BEFORE this raise.
    return currentHandPoints;
  }

  /// Returns the next raise label (ex: "TRUCO!", "SEIS!", "NOVE!", "DOZE!").
  static String getRaiseActionLabel(int nextPoints) {
    switch (nextPoints) {
      case 3:
      case 4:
        return 'TRUCO!';
      case 6:
      case 8:
        return 'SEIS!';
      case 9:
        return 'NOVE!';
      case 12:
        return 'DOZE!';
      default:
        return 'AUMENTAR!';
    }
  }

  /// Automatically assigns players to Team A or Team B based on seat position
  static Team getTeamForSeat(int seatIndex, GameMode mode) {
    // In all modes (2, 4, 6 players):
    // Even seats (0, 2, 4) belong to Team A
    // Odd seats (1, 3, 5) belong to Team B
    return (seatIndex % 2 == 0) ? Team.teamA : Team.teamB;
  }
}

