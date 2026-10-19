import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../engine/bot_ai.dart';
import '../engine/truco_engine.dart';
import '../engine/truco_rules.dart';
import '../models/card_model.dart';
import '../models/game_state_model.dart';
import '../models/player_model.dart';
import '../models/truco_enums.dart';
import 'auth_service.dart';
import 'firebase_service.dart';

class RoomService extends ChangeNotifier {
  final FirebaseFirestore? _firestore;
  final _uuid = const Uuid();

  // In-memory fallback repository when running locally without Firestore
  final Map<String, GameStateModel> _localRooms = {};
  final Map<String, StreamController<GameStateModel>> _roomControllers = {};

  RoomService()
      : _firestore = FirebaseService.instance.isInitialized
            ? FirebaseFirestore.instance
            : null;

  static const List<String> _botNames = [
    'Zé da Esquina',
    'Tonho do Baralho',
    'Chico Picafumo',
    'Tião do Zap',
    'Bastião Truqueiro',
  ];

  static const List<String> _botAvatars = ['🤠', '😎', '👨‍🌾', '🧔', '👴'];

  /// Generates a human-friendly 6-character room code, e.g. "TRU-482"
  String _generateRoomCode() {
    final rand = Random();
    final number = rand.nextInt(900) + 100;
    return 'TRU$number';
  }

  /// Creates a new private room
  Future<GameStateModel> createRoom({
    required GameMode mode,
    required TrucoVariant variant,
    required AppUser hostUser,
  }) async {
    final roomId = _uuid.v4();
    final roomCode = _generateRoomCode();

    final hostPlayer = PlayerModel(
      id: hostUser.id,
      name: hostUser.displayName,
      seatIndex: 0,
      team: Team.teamA,
      isHost: true,
      isReady: true,
      avatar: hostUser.avatar,
    );

    final initialState = GameStateModel(
      roomId: roomId,
      roomCode: roomCode,
      mode: mode,
      variant: variant,
      status: GameStatus.waitingForPlayers,
      players: [hostPlayer],
      handPoints: variant.initialPoints,
      lastMessage: 'Sala criada por ${hostUser.displayName}. Código: $roomCode',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (_firestore != null) {
      await _firestore.collection('rooms').doc(roomId).set(initialState.toMap());
    } else {
      _saveLocalRoom(initialState);
    }

    notifyListeners();
    return initialState;
  }

  /// Joins an existing room by its 6-character code
  Future<GameStateModel> joinRoomByCode({
    required String code,
    required AppUser user,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    GameStateModel? state;
    if (_firestore != null) {
      final query = await _firestore
          .collection('rooms')
          .where('roomCode', isEqualTo: cleanCode)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Sala não encontrada para o código $cleanCode');
      }
      state = GameStateModel.fromMap(query.docs.first.data());
    } else {
      for (final r in _localRooms.values) {
        if (r.roomCode == cleanCode) {
          state = r;
          break;
        }
      }
      if (state == null) {
        throw Exception('Sala não encontrada para o código $cleanCode');
      }
    }

    // Check if player is already in this room
    final existingIndex = state.players.indexWhere((p) => p.id == user.id);
    if (existingIndex >= 0) {
      return state;
    }

    if (state.players.length >= state.mode.maxPlayers) {
      throw Exception('A sala já atingiu o limite de ${state.mode.maxPlayers} jogadores.');
    }

    final newSeatIndex = state.players.length;
    final team = TrucoRules.getTeamForSeat(newSeatIndex, state.mode);

    final newPlayer = PlayerModel(
      id: user.id,
      name: user.displayName,
      seatIndex: newSeatIndex,
      team: team,
      isHost: false,
      isReady: true,
      avatar: user.avatar,
    );

    final updatedPlayers = List<PlayerModel>.from(state.players)..add(newPlayer);
    final isFull = updatedPlayers.length == state.mode.maxPlayers;

    final updatedState = state.copyWith(
      players: updatedPlayers,
      status: isFull ? GameStatus.readyToStart : GameStatus.waitingForPlayers,
      lastMessage: '${user.displayName} entrou na sala! (${team.label})',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _updateRoom(updatedState);
    return updatedState;
  }

  /// Adds a bot to an open seat
  Future<GameStateModel> addBot(String roomId) async {
    final state = await getRoomState(roomId);
    if (state.players.length >= state.mode.maxPlayers) {
      throw Exception('Mesa já está cheia.');
    }

    final seat = state.players.length;
    final team = TrucoRules.getTeamForSeat(seat, state.mode);
    final botName = _botNames[seat % _botNames.length];
    final botAvatar = _botAvatars[seat % _botAvatars.length];

    final botPlayer = PlayerModel(
      id: 'bot_${_uuid.v4().substring(0, 6)}',
      name: botName,
      seatIndex: seat,
      team: team,
      isHost: false,
      isReady: true,
      isBot: true,
      avatar: botAvatar,
    );

    final updatedPlayers = List<PlayerModel>.from(state.players)..add(botPlayer);
    final isFull = updatedPlayers.length == state.mode.maxPlayers;

    final updatedState = state.copyWith(
      players: updatedPlayers,
      status: isFull ? GameStatus.readyToStart : GameStatus.waitingForPlayers,
      lastMessage: '$botName (Bot) sentou na mesa. (${team.label})',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _updateRoom(updatedState);
    return updatedState;
  }

  /// Starts the match once table is full
  Future<GameStateModel> startMatch(String roomId) async {
    final state = await getRoomState(roomId);
    final startedState = TrucoEngine.startMatch(state);
    await _updateRoom(startedState);

    // If starter player is a bot, schedule bot play
    _checkAndTriggerBotTurn(startedState);
    return startedState;
  }

  /// Plays a card
  Future<GameStateModel> playCard({
    required String roomId,
    required String playerId,
    required CardModel card,
    bool isFaceDown = false,
  }) async {
    final state = await getRoomState(roomId);
    final newState = TrucoEngine.playCard(state, playerId, card, isFaceDown: isFaceDown);
    await _updateRoom(newState);

    if (newState.status.isInterval) {
      _checkAndScheduleInterval(newState);
    } else {
      _checkAndTriggerBotTurn(newState);
    }
    return newState;
  }

  /// Calls Truco / Seis / Nove / Doze
  Future<GameStateModel> callTruco({
    required String roomId,
    required String playerId,
  }) async {
    final state = await getRoomState(roomId);
    final newState = TrucoEngine.callTruco(state, playerId);
    await _updateRoom(newState);

    _checkAndTriggerBotTrucoResponse(newState);
    return newState;
  }

  /// Responds to a Truco call
  Future<GameStateModel> respondToTruco({
    required String roomId,
    required String playerId,
    required bool accept,
    bool raiseInstead = false,
  }) async {
    final state = await getRoomState(roomId);
    final newState = TrucoEngine.respondToTruco(
      state,
      playerId,
      accept: accept,
      raiseInstead: raiseInstead,
    );
    await _updateRoom(newState);

    if (newState.status.isInterval) {
      _checkAndScheduleInterval(newState);
    } else if (newState.trucoState.isPending) {
      _checkAndTriggerBotTrucoResponse(newState);
    } else {
      _checkAndTriggerBotTurn(newState);
    }
    return newState;
  }

  /// Responds to Mão de 11 / Mão de 10
  Future<GameStateModel> respondSpecialHand({
    required String roomId,
    required String playerId,
    required bool accept,
  }) async {
    final state = await getRoomState(roomId);
    final newState = TrucoEngine.respondSpecialHand(state, playerId, accept);
    await _updateRoom(newState);

    if (newState.status.isInterval) {
      _checkAndScheduleInterval(newState);
    } else {
      _checkAndTriggerBotTurn(newState);
    }
    return newState;
  }

  /// Quick chat / taunt
  Future<void> sendChatMessage({
    required String roomId,
    required String senderName,
    required String message,
  }) async {
    final state = await getRoomState(roomId);
    final updated = state.copyWith(
      lastMessage: '$senderName: "$message"',
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _updateRoom(updated);
  }

  /// Stream of room updates
  Stream<GameStateModel> streamRoom(String roomId) {
    if (_firestore != null) {
      return _firestore
          .collection('rooms')
          .doc(roomId)
          .snapshots()
          .where((doc) => doc.exists && doc.data() != null)
          .map((doc) => GameStateModel.fromMap(doc.data()!));
    } else {
      return _getOrCreateLocalStream(roomId);
    }
  }

  /// Fetches instantaneous room state
  Future<GameStateModel> getRoomState(String roomId) async {
    if (_firestore != null) {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Sala não encontrada.');
      }
      return GameStateModel.fromMap(doc.data()!);
    } else {
      final state = _localRooms[roomId];
      if (state == null) throw Exception('Sala não encontrada.');
      return state;
    }
  }

  // --- ROUND INTERVAL & BOT AUTOMATION LOGIC ---

  void _checkAndScheduleInterval(GameStateModel state) {
    if (!state.status.isInterval) return;

    Timer(const Duration(seconds: 5), () async {
      try {
        final freshState = await getRoomState(state.roomId);
        if (!freshState.status.isInterval) return;

        final advancedState = TrucoEngine.advanceAfterInterval(freshState);
        await _updateRoom(advancedState);

        _checkAndTriggerBotTurn(advancedState);
      } catch (e) {
        debugPrint('[RoomService] Erro ao avançar intervalo de rodada: $e');
      }
    });
  }

  void _checkAndTriggerBotTurn(GameStateModel state) {
    if (state.status != GameStatus.playing) return;
    if (state.trucoState.isPending) return;

    final currentTurnPlayer = state.currentTurnPlayer;
    if (currentTurnPlayer == null || !currentTurnPlayer.isBot) return;

    // Run bot action after natural delay (700ms - 1.2s)
    Future.delayed(const Duration(milliseconds: 900), () async {
      try {
        final freshState = await getRoomState(state.roomId);
        if (freshState.currentTurnPlayer?.id != currentTurnPlayer.id) return;
        if (freshState.trucoState.isPending) return;

        // Check if bot wants to shout Truco before playing!
        if (BotAI.shouldCallTruco(freshState, currentTurnPlayer)) {
          await callTruco(roomId: freshState.roomId, playerId: currentTurnPlayer.id);
          return;
        }

        // Play card
        final choice = BotAI.chooseCardToPlay(freshState, currentTurnPlayer);
        await playCard(
          roomId: freshState.roomId,
          playerId: currentTurnPlayer.id,
          card: choice.card,
          isFaceDown: choice.isFaceDown,
        );
      } catch (e) {
        debugPrint('[BotAI] Erro no turno do bot: $e');
      }
    });
  }

  void _checkAndTriggerBotTrucoResponse(GameStateModel state) {
    if (!state.trucoState.isPending) return;

    // Check if opposing team has a bot to respond
    final opposingTeam = state.trucoProposerTeam!.opponent;
    final botsInOpponentTeam = state.players
        .where((p) => p.team == opposingTeam && p.isBot)
        .toList();

    if (botsInOpponentTeam.isEmpty) return;
    final respondingBot = botsInOpponentTeam.first;

    Future.delayed(const Duration(milliseconds: 1200), () async {
      try {
        final freshState = await getRoomState(state.roomId);
        if (!freshState.trucoState.isPending) return;

        final decision = BotAI.respondToTrucoCall(freshState, respondingBot);
        await respondToTruco(
          roomId: freshState.roomId,
          playerId: respondingBot.id,
          accept: decision.accept,
          raiseInstead: decision.raiseInstead,
        );
      } catch (e) {
        debugPrint('[BotAI] Erro na resposta de Truco do bot: $e');
      }
    });
  }

  // --- INTERNAL HELPER METHODS ---

  Future<void> _updateRoom(GameStateModel state) async {
    if (_firestore != null) {
      await _firestore.collection('rooms').doc(state.roomId).set(state.toMap());
    } else {
      _saveLocalRoom(state);
    }
  }

  void _saveLocalRoom(GameStateModel state) {
    _localRooms[state.roomId] = state;
    if (_roomControllers.containsKey(state.roomId)) {
      _roomControllers[state.roomId]!.add(state);
    }
    notifyListeners();
  }

  Stream<GameStateModel> _getOrCreateLocalStream(String roomId) {
    if (!_roomControllers.containsKey(roomId)) {
      _roomControllers[roomId] = StreamController<GameStateModel>.broadcast();
      if (_localRooms.containsKey(roomId)) {
        _roomControllers[roomId]!.add(_localRooms[roomId]!);
      }
    }
    return _roomControllers[roomId]!.stream;
  }
}

