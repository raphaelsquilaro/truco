import 'dart:math';
import '../models/card_model.dart';
import '../models/game_state_model.dart';
import '../models/player_model.dart';
import '../models/truco_enums.dart';
import 'truco_rules.dart';

class BotAI {
  static final _random = Random();

  /// Decides which card a bot should play
  static ({CardModel card, bool isFaceDown}) chooseCardToPlay(
    GameStateModel state,
    PlayerModel bot,
  ) {
    if (bot.hand.isEmpty) {
      throw Exception('Bot hand is empty');
    }

    final currentRound = state.currentRound;
    final variant = state.variant;
    final vira = state.vira;

    // Sort cards in bot's hand by power (ascending)
    final sortedHand = List<CardModel>.from(bot.hand)..sort((a, b) {
      final pa = TrucoRules.getCardPower(a, variant, vira: vira);
      final pb = TrucoRules.getCardPower(b, variant, vira: vira);
      return pa.compareTo(pb);
    });

    // If bot is the first to play in this round:
    if (currentRound.playedCards.isEmpty) {
      // In round 1, usually start with a medium or highest card
      if (state.currentRoundIndex == 0) {
        return (card: sortedHand.last, isFaceDown: false);
      }
      // In subsequent rounds, lead with best card
      return (card: sortedHand.last, isFaceDown: false);
    }

    // Evaluate currently winning card on the table
    final eval = TrucoRules.evaluateRoundWinner(
      currentRound.playedCards,
      variant,
      vira: vira,
    );

    // If partner is ALREADY winning the round with a high card:
    if (eval.winnerTeam == bot.team && eval.winningCard != null) {
      final partnerWinningPower = TrucoRules.getCardPower(eval.winningCard!, variant, vira: vira);
      if (partnerWinningPower >= 8) {
        // Partner has an Ace, 2, 3 or Manilha! Play the lowest card to save resources
        // If not round 1, could even play face down
        return (card: sortedHand.first, isFaceDown: false);
      }
    }

    // Find the lowest card in hand that can beat the current highest on the table
    int highestOnTable = 0;
    for (final p in currentRound.playedCards) {
      final pwr = TrucoRules.getCardPower(p.card, variant, vira: vira);
      if (pwr > highestOnTable) highestOnTable = pwr;
    }

    for (final card in sortedHand) {
      final cardPower = TrucoRules.getCardPower(card, variant, vira: vira);
      if (cardPower > highestOnTable) {
        // Play the minimum card needed to win the round!
        return (card: card, isFaceDown: false);
      }
    }

    // If bot cannot beat the highest card on table:
    // Discard the lowest card (corta o chumbo)
    // If round > 0, bot might play face down
    final canPlayFaceDown = state.currentRoundIndex > 0 && _random.nextDouble() < 0.4;
    return (card: sortedHand.first, isFaceDown: canPlayFaceDown);
  }

  /// Decides if bot wants to call Truco / Seis / etc.
  static bool shouldCallTruco(GameStateModel state, PlayerModel bot) {
    if (state.isSpecialHand) return false;
    if (state.trucoState.isPending) return false;
    if (state.trucoProposerTeam == bot.team && state.trucoState == TrucoCallState.accepted) {
      return false;
    }

    final variant = state.variant;
    final vira = state.vira;

    // Count strong cards in bot's hand
    int manilhasCount = 0;
    int strongCardsCount = 0;

    for (final card in bot.hand) {
      final power = TrucoRules.getCardPower(card, variant, vira: vira);
      if (power >= 1000) {
        manilhasCount++;
      } else if (power >= 9) {
        // 2 or 3
        strongCardsCount++;
      }
    }

    // If bot has at least 1 manilha and 1 strong card, or 2 manilhas: high chance of calling Truco!
    if (manilhasCount >= 2 || (manilhasCount >= 1 && strongCardsCount >= 1)) {
      return _random.nextDouble() < 0.65;
    }

    // Occasional bluff (10% chance)
    if (_random.nextDouble() < 0.10 && state.currentRoundIndex == 0) {
      return true;
    }

    return false;
  }

  /// Decides how bot responds to a Truco call (accept, refuse, or raise)
  static ({bool accept, bool raiseInstead}) respondToTrucoCall(
    GameStateModel state,
    PlayerModel bot,
  ) {
    final variant = state.variant;
    final vira = state.vira;

    int totalPower = 0;
    int manilhas = 0;

    for (final card in bot.hand) {
      final power = TrucoRules.getCardPower(card, variant, vira: vira);
      totalPower += power;
      if (power >= 1000) manilhas++;
    }

    // If bot has monster hand (2 manilhas or Zap), consider raising!
    if (manilhas >= 2 && state.pendingTrucoValue < 9 && _random.nextDouble() < 0.5) {
      return (accept: true, raiseInstead: true);
    }

    // If bot has at least 1 manilha or strong card: accept!
    if (manilhas >= 1 || totalPower >= 15) {
      return (accept: true, raiseInstead: false);
    }

    // Otherwise, 40% chance of accepting (guts) or 60% running
    final accept = _random.nextDouble() < 0.40;
    return (accept: accept, raiseInstead: false);
  }

  /// Decides for Mão de 11 / Mão de 10
  static bool decideSpecialHand(GameStateModel state, PlayerModel bot) {
    final variant = state.variant;
    final vira = state.vira;

    int manilhas = 0;
    for (final card in bot.hand) {
      final power = TrucoRules.getCardPower(card, variant, vira: vira);
      if (power >= 1000) manilhas++;
    }

    // Play if bot has at least 1 manilha
    return manilhas >= 1;
  }
}

