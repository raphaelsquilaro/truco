import 'card_model.dart';
import 'truco_enums.dart';

class PlayedCard {
  final String playerId;
  final String playerName;
  final int seatIndex;
  final Team team;
  final CardModel card;
  final bool isFaceDown;

  const PlayedCard({
    required this.playerId,
    required this.playerName,
    required this.seatIndex,
    required this.team,
    required this.card,
    this.isFaceDown = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'seatIndex': seatIndex,
      'team': team.name,
      'card': card.toMap(),
      'isFaceDown': isFaceDown,
    };
  }

  factory PlayedCard.fromMap(Map<String, dynamic> map) {
    return PlayedCard(
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? '',
      seatIndex: map['seatIndex'] ?? 0,
      team: Team.values.firstWhere(
        (t) => t.name == map['team'],
        orElse: () => Team.teamA,
      ),
      card: CardModel.fromMap(Map<String, dynamic>.from(map['card'])),
      isFaceDown: map['isFaceDown'] ?? false,
    );
  }
}

class RoundModel {
  final int roundIndex; // 0, 1, 2 (Rounds 1, 2, 3)
  final List<PlayedCard> playedCards;
  final Team? winnerTeam; // null if tied (canguera)
  final String? winningPlayerId;
  final CardModel? winningCard;
  final bool isTied;

  const RoundModel({
    required this.roundIndex,
    this.playedCards = const [],
    this.winnerTeam,
    this.winningPlayerId,
    this.winningCard,
    this.isTied = false,
  });

  RoundModel copyWith({
    int? roundIndex,
    List<PlayedCard>? playedCards,
    Team? winnerTeam,
    String? winningPlayerId,
    CardModel? winningCard,
    bool? isTied,
  }) {
    return RoundModel(
      roundIndex: roundIndex ?? this.roundIndex,
      playedCards: playedCards ?? this.playedCards,
      winnerTeam: winnerTeam ?? this.winnerTeam,
      winningPlayerId: winningPlayerId ?? this.winningPlayerId,
      winningCard: winningCard ?? this.winningCard,
      isTied: isTied ?? this.isTied,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roundIndex': roundIndex,
      'playedCards': playedCards.map((p) => p.toMap()).toList(),
      'winnerTeam': winnerTeam?.name,
      'winningPlayerId': winningPlayerId,
      'winningCard': winningCard?.toMap(),
      'isTied': isTied,
    };
  }

  factory RoundModel.fromMap(Map<String, dynamic> map) {
    return RoundModel(
      roundIndex: map['roundIndex'] ?? 0,
      playedCards: (map['playedCards'] as List<dynamic>? ?? [])
          .map((p) => PlayedCard.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      winnerTeam: map['winnerTeam'] != null
          ? Team.values.firstWhere((t) => t.name == map['winnerTeam'])
          : null,
      winningPlayerId: map['winningPlayerId'],
      winningCard: map['winningCard'] != null
          ? CardModel.fromMap(Map<String, dynamic>.from(map['winningCard']))
          : null,
      isTied: map['isTied'] ?? false,
    );
  }
}

