import 'card_model.dart';
import 'truco_enums.dart';

class PlayerModel {
  final String id;
  final String name;
  final int seatIndex;
  final Team team;
  final List<CardModel> hand;
  final bool isHost;
  final bool isReady;
  final bool isBot;
  final String avatar;
  final bool isConnected;

  const PlayerModel({
    required this.id,
    required this.name,
    required this.seatIndex,
    required this.team,
    this.hand = const [],
    this.isHost = false,
    this.isReady = false,
    this.isBot = false,
    this.avatar = '🤠',
    this.isConnected = true,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    int? seatIndex,
    Team? team,
    List<CardModel>? hand,
    bool? isHost,
    bool? isReady,
    bool? isBot,
    String? avatar,
    bool? isConnected,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      seatIndex: seatIndex ?? this.seatIndex,
      team: team ?? this.team,
      hand: hand ?? this.hand,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      isBot: isBot ?? this.isBot,
      avatar: avatar ?? this.avatar,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'seatIndex': seatIndex,
      'team': team.name,
      'hand': hand.map((c) => c.toMap()).toList(),
      'isHost': isHost,
      'isReady': isReady,
      'isBot': isBot,
      'avatar': avatar,
      'isConnected': isConnected,
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      seatIndex: map['seatIndex'] ?? 0,
      team: Team.values.firstWhere(
        (t) => t.name == map['team'],
        orElse: () => Team.teamA,
      ),
      hand: (map['hand'] as List<dynamic>? ?? [])
          .map((c) => CardModel.fromMap(Map<String, dynamic>.from(c)))
          .toList(),
      isHost: map['isHost'] ?? false,
      isReady: map['isReady'] ?? false,
      isBot: map['isBot'] ?? false,
      avatar: map['avatar'] ?? '🤠',
      isConnected: map['isConnected'] ?? true,
    );
  }

  @override
  String toString() => '$name (Seat $seatIndex, ${team.label})';
}

