import 'package:flutter/material.dart';

enum Suit {
  ouros('Ouros', '♦', Color(0xFFD32F2F), 1),
  espadas('Espadas', '♠', Color(0xFF212121), 2),
  copas('Copas', '♥', Color(0xFFD32F2F), 3),
  paus('Paus', '♣', Color(0xFF1B5E20), 4);

  final String name;
  final String symbol;
  final Color color;
  final int manilhaPower; // Paus (Zap) > Copas > Espadas > Ouros (Picafumo)

  const Suit(this.name, this.symbol, this.color, this.manilhaPower);
}

enum Rank {
  four('4', 1),
  five('5', 2),
  six('6', 3),
  seven('7', 4),
  queen('Q', 5),
  jack('J', 6),
  king('K', 7),
  ace('A', 8),
  two('2', 9),
  three('3', 10);

  final String symbol;
  final int basePower;

  const Rank(this.symbol, this.basePower);

  Rank get nextInCycle {
    switch (this) {
      case Rank.four:
        return Rank.five;
      case Rank.five:
        return Rank.six;
      case Rank.six:
        return Rank.seven;
      case Rank.seven:
        return Rank.queen;
      case Rank.queen:
        return Rank.jack;
      case Rank.jack:
        return Rank.king;
      case Rank.king:
        return Rank.ace;
      case Rank.ace:
        return Rank.two;
      case Rank.two:
        return Rank.three;
      case Rank.three:
        return Rank.four;
    }
  }
}

class CardModel {
  final Rank rank;
  final Suit suit;
  final bool isFaceDown;

  const CardModel({
    required this.rank,
    required this.suit,
    this.isFaceDown = false,
  });

  String get id => '${rank.symbol}_${suit.name.toLowerCase()}';

  String get displayName => isFaceDown ? 'Carta Oculta' : '${rank.symbol} de ${suit.name}';

  String get shortDisplay => isFaceDown ? '?' : '${rank.symbol}${suit.symbol}';

  CardModel copyWith({
    Rank? rank,
    Suit? suit,
    bool? isFaceDown,
  }) {
    return CardModel(
      rank: rank ?? this.rank,
      suit: suit ?? this.suit,
      isFaceDown: isFaceDown ?? this.isFaceDown,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank.name,
      'suit': suit.name,
      'isFaceDown': isFaceDown,
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      rank: Rank.values.firstWhere((r) => r.name == map['rank']),
      suit: Suit.values.firstWhere((s) => s.name == map['suit']),
      isFaceDown: map['isFaceDown'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel &&
          runtimeType == other.runtimeType &&
          rank == other.rank &&
          suit == other.suit &&
          isFaceDown == other.isFaceDown;

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode ^ isFaceDown.hashCode;

  @override
  String toString() => shortDisplay;
}

