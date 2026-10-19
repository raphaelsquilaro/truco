import 'card_model.dart';
import 'player_model.dart';
import 'round_model.dart';
import 'truco_enums.dart';

class GameStateModel {
  final String roomId;
  final String roomCode;
  final GameMode mode;
  final TrucoVariant variant;
  final GameStatus status;
  final List<PlayerModel> players;
  final int scoreTeamA;
  final int scoreTeamB;
  final int currentDealerIndex;
  final int currentTurnPlayerIndex;
  final int handRoundStarterPlayerIndex;
  final int handPoints;
  final TrucoCallState trucoState;
  final Team? trucoProposerTeam;
  final String? trucoProposerPlayerId;
  final int pendingTrucoValue;
  final CardModel? vira;
  final List<RoundModel> rounds;
  final int currentRoundIndex;
  final Team? handWinner;
  final Team? matchWinner;
  final bool isSpecialHand; // Mão de 11 (Paulista) ou Mão de 10 (Mineiro)
  final Team? specialHandTeam;
  final bool? specialHandAccepted;
  final String lastMessage;
  final int updatedAt;

  // Round finished interval and subsequent round highlights
  final Team? roundWinnerTeam;
  final String? roundWinningPlayerName;
  final CardModel? roundWinningCard;
  final bool isRoundTied;
  final int nextRoundIndex;
  final String? nextStarterPlayerName;
  final int intervalExpiresAt;

  const GameStateModel({
    required this.roomId,
    required this.roomCode,
    required this.mode,
    required this.variant,
    this.status = GameStatus.waitingForPlayers,
    this.players = const [],
    this.scoreTeamA = 0,
    this.scoreTeamB = 0,
    this.currentDealerIndex = 0,
    this.currentTurnPlayerIndex = 0,
    this.handRoundStarterPlayerIndex = 0,
    this.handPoints = 1,
    this.trucoState = TrucoCallState.none,
    this.trucoProposerTeam,
    this.trucoProposerPlayerId,
    this.pendingTrucoValue = 0,
    this.vira,
    this.rounds = const [],
    this.currentRoundIndex = 0,
    this.handWinner,
    this.matchWinner,
    this.isSpecialHand = false,
    this.specialHandTeam,
    this.specialHandAccepted,
    this.lastMessage = 'Aguardando jogadores...',
    this.updatedAt = 0,
    this.roundWinnerTeam,
    this.roundWinningPlayerName,
    this.roundWinningCard,
    this.isRoundTied = false,
    this.nextRoundIndex = 0,
    this.nextStarterPlayerName,
    this.intervalExpiresAt = 0,
  });

  PlayerModel? get currentTurnPlayer {
    if (players.isEmpty || currentTurnPlayerIndex >= players.length) return null;
    return players[currentTurnPlayerIndex];
  }

  PlayerModel? getPlayerById(String id) {
    try {
      return players.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  RoundModel get currentRound {
    if (rounds.isEmpty) return const RoundModel(roundIndex: 0);
    if (currentRoundIndex < rounds.length) return rounds[currentRoundIndex];
    return rounds.last;
  }

  GameStateModel copyWith({
    String? roomId,
    String? roomCode,
    GameMode? mode,
    TrucoVariant? variant,
    GameStatus? status,
    List<PlayerModel>? players,
    int? scoreTeamA,
    int? scoreTeamB,
    int? currentDealerIndex,
    int? currentTurnPlayerIndex,
    int? handRoundStarterPlayerIndex,
    int? handPoints,
    TrucoCallState? trucoState,
    Team? trucoProposerTeam,
    String? trucoProposerPlayerId,
    int? pendingTrucoValue,
    CardModel? vira,
    List<RoundModel>? rounds,
    int? currentRoundIndex,
    Team? handWinner,
    Team? matchWinner,
    bool? isSpecialHand,
    Team? specialHandTeam,
    bool? specialHandAccepted,
    String? lastMessage,
    int? updatedAt,
    Team? roundWinnerTeam,
    String? roundWinningPlayerName,
    CardModel? roundWinningCard,
    bool? isRoundTied,
    int? nextRoundIndex,
    String? nextStarterPlayerName,
    int? intervalExpiresAt,
  }) {
    return GameStateModel(
      roomId: roomId ?? this.roomId,
      roomCode: roomCode ?? this.roomCode,
      mode: mode ?? this.mode,
      variant: variant ?? this.variant,
      status: status ?? this.status,
      players: players ?? this.players,
      scoreTeamA: scoreTeamA ?? this.scoreTeamA,
      scoreTeamB: scoreTeamB ?? this.scoreTeamB,
      currentDealerIndex: currentDealerIndex ?? this.currentDealerIndex,
      currentTurnPlayerIndex: currentTurnPlayerIndex ?? this.currentTurnPlayerIndex,
      handRoundStarterPlayerIndex:
          handRoundStarterPlayerIndex ?? this.handRoundStarterPlayerIndex,
      handPoints: handPoints ?? this.handPoints,
      trucoState: trucoState ?? this.trucoState,
      trucoProposerTeam: trucoProposerTeam ?? this.trucoProposerTeam,
      trucoProposerPlayerId: trucoProposerPlayerId ?? this.trucoProposerPlayerId,
      pendingTrucoValue: pendingTrucoValue ?? this.pendingTrucoValue,
      vira: vira ?? this.vira,
      rounds: rounds ?? this.rounds,
      currentRoundIndex: currentRoundIndex ?? this.currentRoundIndex,
      handWinner: handWinner ?? this.handWinner,
      matchWinner: matchWinner ?? this.matchWinner,
      isSpecialHand: isSpecialHand ?? this.isSpecialHand,
      specialHandTeam: specialHandTeam ?? this.specialHandTeam,
      specialHandAccepted: specialHandAccepted ?? this.specialHandAccepted,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      roundWinnerTeam: roundWinnerTeam ?? this.roundWinnerTeam,
      roundWinningPlayerName: roundWinningPlayerName ?? this.roundWinningPlayerName,
      roundWinningCard: roundWinningCard ?? this.roundWinningCard,
      isRoundTied: isRoundTied ?? this.isRoundTied,
      nextRoundIndex: nextRoundIndex ?? this.nextRoundIndex,
      nextStarterPlayerName: nextStarterPlayerName ?? this.nextStarterPlayerName,
      intervalExpiresAt: intervalExpiresAt ?? this.intervalExpiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomCode': roomCode,
      'mode': mode.name,
      'variant': variant.name,
      'status': status.name,
      'players': players.map((p) => p.toMap()).toList(),
      'scoreTeamA': scoreTeamA,
      'scoreTeamB': scoreTeamB,
      'currentDealerIndex': currentDealerIndex,
      'currentTurnPlayerIndex': currentTurnPlayerIndex,
      'handRoundStarterPlayerIndex': handRoundStarterPlayerIndex,
      'handPoints': handPoints,
      'trucoState': trucoState.name,
      'trucoProposerTeam': trucoProposerTeam?.name,
      'trucoProposerPlayerId': trucoProposerPlayerId,
      'pendingTrucoValue': pendingTrucoValue,
      'vira': vira?.toMap(),
      'rounds': rounds.map((r) => r.toMap()).toList(),
      'currentRoundIndex': currentRoundIndex,
      'handWinner': handWinner?.name,
      'matchWinner': matchWinner?.name,
      'isSpecialHand': isSpecialHand,
      'specialHandTeam': specialHandTeam?.name,
      'specialHandAccepted': specialHandAccepted,
      'lastMessage': lastMessage,
      'updatedAt': updatedAt,
      'roundWinnerTeam': roundWinnerTeam?.name,
      'roundWinningPlayerName': roundWinningPlayerName,
      'roundWinningCard': roundWinningCard?.toMap(),
      'isRoundTied': isRoundTied,
      'nextRoundIndex': nextRoundIndex,
      'nextStarterPlayerName': nextStarterPlayerName,
      'intervalExpiresAt': intervalExpiresAt,
    };
  }

  factory GameStateModel.fromMap(Map<String, dynamic> map) {
    return GameStateModel(
      roomId: map['roomId'] ?? '',
      roomCode: map['roomCode'] ?? '',
      mode: GameMode.values.firstWhere(
        (m) => m.name == map['mode'],
        orElse: () => GameMode.fourPlayers,
      ),
      variant: TrucoVariant.values.firstWhere(
        (v) => v.name == map['variant'],
        orElse: () => TrucoVariant.paulista,
      ),
      status: GameStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => GameStatus.waitingForPlayers,
      ),
      players: (map['players'] as List<dynamic>? ?? [])
          .map((p) => PlayerModel.fromMap(Map<String, dynamic>.from(p)))
          .toList(),
      scoreTeamA: map['scoreTeamA'] ?? 0,
      scoreTeamB: map['scoreTeamB'] ?? 0,
      currentDealerIndex: map['currentDealerIndex'] ?? 0,
      currentTurnPlayerIndex: map['currentTurnPlayerIndex'] ?? 0,
      handRoundStarterPlayerIndex: map['handRoundStarterPlayerIndex'] ?? 0,
      handPoints: map['handPoints'] ?? 1,
      trucoState: TrucoCallState.values.firstWhere(
        (t) => t.name == map['trucoState'],
        orElse: () => TrucoCallState.none,
      ),
      trucoProposerTeam: map['trucoProposerTeam'] != null
          ? Team.values.firstWhere((t) => t.name == map['trucoProposerTeam'])
          : null,
      trucoProposerPlayerId: map['trucoProposerPlayerId'],
      pendingTrucoValue: map['pendingTrucoValue'] ?? 0,
      vira: map['vira'] != null
          ? CardModel.fromMap(Map<String, dynamic>.from(map['vira']))
          : null,
      rounds: (map['rounds'] as List<dynamic>? ?? [])
          .map((r) => RoundModel.fromMap(Map<String, dynamic>.from(r)))
          .toList(),
      currentRoundIndex: map['currentRoundIndex'] ?? 0,
      handWinner: map['handWinner'] != null
          ? Team.values.firstWhere((t) => t.name == map['handWinner'])
          : null,
      matchWinner: map['matchWinner'] != null
          ? Team.values.firstWhere((t) => t.name == map['matchWinner'])
          : null,
      isSpecialHand: map['isSpecialHand'] ?? false,
      specialHandTeam: map['specialHandTeam'] != null
          ? Team.values.firstWhere((t) => t.name == map['specialHandTeam'])
          : null,
      specialHandAccepted: map['specialHandAccepted'],
      lastMessage: map['lastMessage'] ?? '',
      updatedAt: map['updatedAt'] ?? 0,
      roundWinnerTeam: map['roundWinnerTeam'] != null
          ? Team.values.firstWhere((t) => t.name == map['roundWinnerTeam'])
          : null,
      roundWinningPlayerName: map['roundWinningPlayerName'],
      roundWinningCard: map['roundWinningCard'] != null
          ? CardModel.fromMap(Map<String, dynamic>.from(map['roundWinningCard']))
          : null,
      isRoundTied: map['isRoundTied'] ?? false,
      nextRoundIndex: map['nextRoundIndex'] ?? 0,
      nextStarterPlayerName: map['nextStarterPlayerName'],
      intervalExpiresAt: map['intervalExpiresAt'] ?? 0,
    );
  }
}
