import 'dart:math';
import '../models/card_model.dart';

class TrucoDeck {
  /// Generates the classic 40-card Brazilian Truco deck (without 8s, 9s, 10s).
  static List<CardModel> createDeck() {
    final List<CardModel> deck = [];
    for (final rank in Rank.values) {
      for (final suit in Suit.values) {
        deck.add(CardModel(rank: rank, suit: suit));
      }
    }
    return deck;
  }

  /// Shuffles the deck using cryptographically sound or random seed
  static List<CardModel> shuffleDeck([List<CardModel>? deck]) {
    final list = List<CardModel>.from(deck ?? createDeck());
    final random = Random();
    list.shuffle(random);
    return list;
  }
}

