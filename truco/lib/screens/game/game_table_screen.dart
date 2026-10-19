import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../engine/truco_rules.dart';
import '../../models/card_model.dart';
import '../../models/game_state_model.dart';
import '../../models/player_model.dart';
import '../../models/truco_enums.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../widgets/animated_played_card_widget.dart';
import '../../widgets/manilha_burst_widget.dart';
import '../../widgets/playing_card_widget.dart';
import '../../widgets/quick_chat_widget.dart';
import '../../widgets/round_interval_banner.dart';
import '../../widgets/score_board_widget.dart';
import '../../widgets/truco_call_dialog.dart';

class GameTableScreen extends StatefulWidget {
  final String roomId;

  const GameTableScreen({super.key, required this.roomId});

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  CardModel? _selectedCard;
  bool _playFaceDown = false;
  String? _lastPlayedCardSignature;
  String? _activeManilhaBurst;
  String? _activeManilhaPlayer;
  int _shakeKey = 0;
  Timer? _burstTimer;

  void _checkForNewManilha(GameStateModel state) {
    final currentRound = state.currentRound;
    if (currentRound.playedCards.isEmpty) return;

    final latestCard = currentRound.playedCards.last;
    final signature =
        '${latestCard.playerId}_${latestCard.card.id}_${currentRound.roundIndex}_${currentRound.playedCards.length}';

    if (_lastPlayedCardSignature != signature) {
      _lastPlayedCardSignature = signature;

      final manilhaName = TrucoRules.getManilhaName(
        latestCard.card,
        state.variant,
        vira: state.vira,
      );

      if (manilhaName != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerManilhaBurst(manilhaName, latestCard.playerName);
        });
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _triggerManilhaBurst(String manilhaName, String playerName) {
    _burstTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _activeManilhaBurst = manilhaName;
      _activeManilhaPlayer = playerName;
      _shakeKey++;
    });

    _burstTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _activeManilhaBurst = null;
          _activeManilhaPlayer = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _burstTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomService = context.watch<RoomService>();
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return StreamBuilder<GameStateModel>(
      stream: roomService.streamRoom(widget.roomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F3018),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          );
        }

        final state = snapshot.data!;
        _checkForNewManilha(state);

        final localPlayer = state.getPlayerById(currentUser.id) ??
            state.players.firstWhere(
              (p) => !p.isBot,
              orElse: () => state.players.first,
            );

        final isMyTurn = state.status == GameStatus.playing &&
            state.currentTurnPlayer?.id == localPlayer.id &&
            !state.trucoState.isPending;

        return Scaffold(
          backgroundColor: const Color(0xFF0D2814),
          appBar: _buildAppBar(context, state),
          body: SafeArea(
            child: Stack(
              children: [
                // Oval Felt Game Table with dynamic shake on manilha slam
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: _shakeKey > 0
                        ? _buildFeltTable(state, localPlayer)
                            .animate(key: ValueKey(_shakeKey))
                            .shake(duration: 450.ms, hz: 6, curve: Curves.easeInOut)
                        : _buildFeltTable(state, localPlayer),
                  ),
                ),

                // Manilha Golden Burst & Shockwave Overlay
                if (_activeManilhaBurst != null)
                  ManilhaBurstWidget(
                    manilhaName: _activeManilhaBurst!,
                    playerName: _activeManilhaPlayer ?? 'Jogador',
                    onDismissed: () {
                      setState(() {
                        _activeManilhaBurst = null;
                        _activeManilhaPlayer = null;
                      });
                    },
                  ),

                // Top Floating Scoreboard
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ScoreBoardWidget(
                      state: state,
                      localPlayerTeam: localPlayer.team,
                    ),
                  ),
                ),

                // 5-second Round / Hand Interval Banner with highlight of subsequent round
                if (state.status.isInterval)
                  Positioned(
                    top: 85,
                    left: 14,
                    right: 14,
                    child: RoundIntervalBanner(state: state),
                  ),

                // Truco Call Banner
                if (state.trucoState.isPending)
                  Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: TrucoCallBanner(
                      state: state,
                      currentUserId: localPlayer.id,
                      onRespond: ({required bool accept, bool raiseInstead = false}) {
                        HapticFeedback.heavyImpact();
                        roomService.respondToTruco(
                          roomId: widget.roomId,
                          playerId: localPlayer.id,
                          accept: accept,
                          raiseInstead: raiseInstead,
                        );
                      },
                    ),
                  ),

                // Mão de 11 / Mão de 10 Dialog Banner
                if (state.isSpecialHand &&
                    state.specialHandAccepted == null &&
                    state.specialHandTeam == localPlayer.team)
                  Positioned(
                    top: 80,
                    left: 20,
                    right: 20,
                    child: _buildSpecialHandBanner(context, state, localPlayer),
                  ),

                // Bottom area: Player hand and controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomPlayerArea(
                    context,
                    state,
                    localPlayer,
                    isMyTurn,
                  ),
                ),

                // Match Finished Celebration Overlay
                if (state.status == GameStatus.matchFinished)
                  Positioned.fill(
                    child: _buildMatchFinishedOverlay(context, state, localPlayer),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GameStateModel state) {
    return AppBar(
      backgroundColor: const Color(0xFF0A1D0F),
      elevation: 4,
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.key, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 4),
                Text(
                  state.roomCode,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${state.variant.label} • ${state.mode.shortLabel}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.forum, color: Color(0xFFFFD700)),
          tooltip: 'Provocações e Falas',
          onPressed: () {
            QuickChatWidget.show(context, (msg) {
              final auth = context.read<AuthService>();
              context.read<RoomService>().sendChatMessage(
                    roomId: widget.roomId,
                    senderName: auth.currentUser?.displayName ?? 'Jogador',
                    message: msg,
                  );
            });
          },
        ),
      ],
    );
  }

  Widget _buildFeltTable(GameStateModel state, PlayerModel localPlayer) {
    return Container(
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFF1E6B34), Color(0xFF10441E), Color(0xFF07220D)],
          radius: 0.85,
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFF5D4037), width: 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Table decorative inner border
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Player positions arranged around the table
          ..._buildOtherPlayerAvatars(state, localPlayer),

          // Center: Vira Card & Played Cards of this trick
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                // Vira or Mineiro Badge
                _buildViraOrVariantHeader(state),
                const SizedBox(height: 12),
                // Cards played in this trick
                _buildPlayedTrickCards(state),
                const SizedBox(height: 8),
                // Status message ticker
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state.lastMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 130), // Spacing for player hand
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOtherPlayerAvatars(GameStateModel state, PlayerModel localPlayer) {
    final otherPlayers = state.players.where((p) => p.id != localPlayer.id).toList();
    final widgets = <Widget>[];

    // Position based on total count
    if (state.mode == GameMode.twoPlayers) {
      if (otherPlayers.isNotEmpty) {
        widgets.add(Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Center(child: _buildPlayerAvatar(otherPlayers[0], state)),
        ));
      }
    } else if (state.mode == GameMode.fourPlayers) {
      // 4 players: Partner at Top, Opponents on Left and Right
      // Order relative to local player:
      final localSeat = localPlayer.seatIndex;
      final partnerSeat = (localSeat + 2) % 4;
      final leftSeat = (localSeat + 3) % 4;
      final rightSeat = (localSeat + 1) % 4;

      final partner = state.players.firstWhere((p) => p.seatIndex == partnerSeat, orElse: () => otherPlayers.first);
      final leftOpponent = state.players.firstWhere((p) => p.seatIndex == leftSeat, orElse: () => otherPlayers.first);
      final rightOpponent = state.players.firstWhere((p) => p.seatIndex == rightSeat, orElse: () => otherPlayers.first);

      widgets.add(Positioned(
        top: 55,
        left: 0,
        right: 0,
        child: Center(child: _buildPlayerAvatar(partner, state, isPartner: true)),
      ));

      widgets.add(Positioned(
        top: 140,
        left: 10,
        child: _buildPlayerAvatar(leftOpponent, state),
      ));

      widgets.add(Positioned(
        top: 140,
        right: 10,
        child: _buildPlayerAvatar(rightOpponent, state),
      ));
    } else {
      // 6 players mode: arranged around the oval
      for (int i = 0; i < otherPlayers.length; i++) {
        final p = otherPlayers[i];
        final isPartner = p.team == localPlayer.team;
        // Distribute top-left, top-center, top-right, mid-left, mid-right
        if (i == 0) {
          widgets.add(Positioned(top: 55, left: 20, child: _buildPlayerAvatar(p, state, isPartner: isPartner)));
        } else if (i == 1) {
          widgets.add(Positioned(top: 55, left: 0, right: 0, child: Center(child: _buildPlayerAvatar(p, state, isPartner: isPartner))));
        } else if (i == 2) {
          widgets.add(Positioned(top: 55, right: 20, child: _buildPlayerAvatar(p, state, isPartner: isPartner)));
        } else if (i == 3) {
          widgets.add(Positioned(top: 150, left: 10, child: _buildPlayerAvatar(p, state, isPartner: isPartner)));
        } else {
          widgets.add(Positioned(top: 150, right: 10, child: _buildPlayerAvatar(p, state, isPartner: isPartner)));
        }
      }
    }

    return widgets;
  }

  Widget _buildPlayerAvatar(PlayerModel player, GameStateModel state, {bool isPartner = false}) {
    final isTurn = state.currentTurnPlayer?.id == player.id && state.status == GameStatus.playing;
    final isTeamA = player.team == Team.teamA;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isTurn
                  ? const Color(0xFFFFD700)
                  : (isTeamA ? const Color(0xFF4FC3F7) : const Color(0xFFEF5350)),
              width: isTurn ? 3 : 1.5,
            ),
            boxShadow: isTurn
                ? [
                    const BoxShadow(
                      color: Color(0xFFFFD700),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF212121),
            child: Text(
              player.avatar,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPartner)
                const Text('★ ', style: TextStyle(color: Color(0xFFFFD700), fontSize: 9)),
              Text(
                player.name.length > 9 ? '${player.name.substring(0, 8)}…' : player.name,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // Cards remaining count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            player.hand.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 5,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(1),
                border: Border.all(color: Colors.white54, width: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViraOrVariantHeader(GameStateModel state) {
    if (state.variant == TrucoVariant.paulista && state.vira != null) {
      final manilhaRank = state.vira!.rank.nextInCycle;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vira card
          PlayingCardWidget(
            card: state.vira!,
            width: 48,
            height: 68,
            isPlayable: false,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VIRA',
                  style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'MANILHA: ${manilhaRank.symbol}',
                  style: const TextStyle(
                    color: Color(0xFF2E1C00),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Mineiro fixed manilhas badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD700), width: 1),
        ),
        child: const Column(
          children: [
            Text(
              'TRUCO MINEIRO (Manilhas Velhas)',
              style: TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              '4♣ (Zap) > 7♥ > A♠ > 7♦',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPlayedTrickCards(GameStateModel state) {
    final round = state.currentRound;
    if (round.playedCards.isEmpty) {
      return Container(
        height: 90,
        alignment: Alignment.center,
        child: const Text(
          'Aguardando primeira jogada...',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return Wrap(
      spacing: 14,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: List.generate(round.playedCards.length, (index) {
        final played = round.playedCards[index];
        final isLatest = index == round.playedCards.length - 1;
        final manilhaName = TrucoRules.getManilhaName(
          played.card,
          state.variant,
          vira: state.vira,
        );
        final isManilha = manilhaName != null;
        final isRoundWinner = state.status.isInterval &&
            state.roundWinningCard != null &&
            !state.isRoundTied &&
            state.roundWinningCard == played.card;

        return AnimatedPlayedCardWidget(
          key: ValueKey('${played.playerId}_${played.card.id}_$index'),
          playedCard: played,
          isManilha: isManilha,
          manilhaLabel: manilhaName,
          isLatest: isLatest,
          isRoundWinner: isRoundWinner,
          cardWidth: 56,
          cardHeight: 80,
        );
      }),
    );
  }

  Widget _buildBottomPlayerArea(
    BuildContext context,
    GameStateModel state,
    PlayerModel localPlayer,
    bool isMyTurn,
  ) {
    final nextRaisePoints = TrucoRules.getNextRaisePoints(state.handPoints, state.variant);
    final raiseLabel = TrucoRules.getRaiseActionLabel(nextRaisePoints);
    final canCallTruco = isMyTurn &&
        !state.isSpecialHand &&
        !state.trucoState.isPending &&
        state.trucoProposerTeam != localPlayer.team;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A12).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hand cards row with entrance animations
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(localPlayer.hand.length, (index) {
              final card = localPlayer.hand[index];
              final isSelected = _selectedCard == card;
              final manilhaName = TrucoRules.getManilhaName(
                card,
                state.variant,
                vira: state.vira,
              );
              final isManilha = manilhaName != null;

              Widget cardItem = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: PlayingCardWidget(
                  card: card,
                  isSelected: isSelected,
                  isManilha: isManilha,
                  isPlayable: isMyTurn,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_selectedCard == card) {
                        _selectedCard = null;
                      } else {
                        _selectedCard = card;
                      }
                    });
                  },
                ),
              );

              // Dealing animation when cards arrive in hand
              cardItem = cardItem
                  .animate()
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 250.ms,
                    curve: Curves.easeOutBack,
                  )
                  .slideY(begin: 0.3, end: 0, duration: 250.ms);

              return cardItem;
            }),
          ),

          const SizedBox(height: 10),

          // Actions row: Truco, Carta Coberta, Jogar Carta
          Row(
            children: [
              // Truco Shout Button
              ElevatedButton.icon(
                onPressed: canCallTruco
                    ? () {
                        HapticFeedback.heavyImpact();
                        context.read<RoomService>().callTruco(
                              roomId: widget.roomId,
                              playerId: localPlayer.id,
                            );
                      }
                    : null,
                icon: const Icon(Icons.flash_on, size: 18),
                label: Text(raiseLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD84315),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(width: 8),

              // Carta Coberta toggle (disabled in trick 1)
              if (state.currentRoundIndex > 0)
                FilterChip(
                  label: const Text('Oculta', style: TextStyle(fontSize: 12)),
                  selected: _playFaceDown,
                  selectedColor: const Color(0xFF5D4037),
                  checkmarkColor: Colors.amber,
                  backgroundColor: Colors.white12,
                  labelStyle: TextStyle(
                    color: _playFaceDown ? Colors.amber : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    setState(() {
                      _playFaceDown = val;
                    });
                  },
                ),

              const Spacer(),

              // Confirm Play Selected Card button
              ElevatedButton.icon(
                onPressed: (isMyTurn && _selectedCard != null)
                    ? () {
                        HapticFeedback.mediumImpact();
                        final cardToPlay = _selectedCard!;
                        final faceDown = _playFaceDown;
                        setState(() {
                          _selectedCard = null;
                          _playFaceDown = false;
                        });
                        context.read<RoomService>().playCard(
                              roomId: widget.roomId,
                              playerId: localPlayer.id,
                              card: cardToPlay,
                              isFaceDown: faceDown,
                            );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  isMyTurn ? 'JOGAR' : 'VEZ DELE',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white30,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialHandBanner(
    BuildContext context,
    GameStateModel state,
    PlayerModel localPlayer,
  ) {
    final title = state.variant == TrucoVariant.paulista ? 'MÃO DE 11!' : 'MÃO DE 10!';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Seu time atingiu a pontuação decisiva! Desejam jogar a mão?',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<RoomService>().respondSpecialHand(
                        roomId: widget.roomId,
                        playerId: localPlayer.id,
                        accept: false,
                      );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                child: const Text('CORRER (1 pt para eles)'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<RoomService>().respondSpecialHand(
                        roomId: widget.roomId,
                        playerId: localPlayer.id,
                        accept: true,
                      );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                child: const Text('JOGAR (3 pts)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchFinishedOverlay(
    BuildContext context,
    GameStateModel state,
    PlayerModel localPlayer,
  ) {
    final isWinner = state.matchWinner == localPlayer.team;
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWinner ? '🏆 VITÓRIA! 🏆' : 'DERROTA 😢',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isWinner ? const Color(0xFFFFD700) : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${state.matchWinner?.label} venceu a partida!',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Placar Final: Time A ${state.scoreTeamA} x ${state.scoreTeamB} Time B',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('VOLTAR AO MENU', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
