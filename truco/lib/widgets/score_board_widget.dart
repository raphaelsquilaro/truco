import 'package:flutter/material.dart';
import '../models/game_state_model.dart';
import '../models/truco_enums.dart';

class ScoreBoardWidget extends StatelessWidget {
  final GameStateModel state;
  final Team localPlayerTeam;

  const ScoreBoardWidget({
    super.key,
    required this.state,
    required this.localPlayerTeam,
  });

  @override
  Widget build(BuildContext context) {
    final isTeamA = localPlayerTeam == Team.teamA;
    final teamALabel = isTeamA ? 'NÓS' : 'TIME A';
    final teamBLabel = !isTeamA ? 'NÓS' : 'TIME B';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team A Score
          _buildTeamScore(
            label: teamALabel,
            score: state.scoreTeamA,
            color: const Color(0xFF4FC3F7),
            isLocal: isTeamA,
          ),

          const SizedBox(width: 12),

          // Center: Hand Points & Round Trick Dots
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hand points badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: state.handPoints > (state.variant == TrucoVariant.paulista ? 1 : 2)
                        ? [const Color(0xFFFF8F00), const Color(0xFFD84315)]
                        : [const Color(0xFF37474F), const Color(0xFF263238)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.handPoints > 1 ? const Color(0xFFFFD700) : Colors.white24,
                    width: 1,
                  ),
                ),
                child: Text(
                  _getStakeText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Round Trick Dots (1st, 2nd, 3rd)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTrickDot(0),
                  const SizedBox(width: 6),
                  _buildTrickDot(1),
                  const SizedBox(width: 6),
                  _buildTrickDot(2),
                ],
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Team B Score
          _buildTeamScore(
            label: teamBLabel,
            score: state.scoreTeamB,
            color: const Color(0xFFEF5350),
            isLocal: !isTeamA,
          ),
        ],
      ),
    );
  }

  String _getStakeText() {
    if (state.handPoints <= 1 && state.variant == TrucoVariant.paulista) {
      return 'VALE 1 PT';
    }
    if (state.handPoints <= 2 && state.variant == TrucoVariant.mineiro) {
      return 'VALE 2 PTS';
    }
    return 'TRUCO! ${state.handPoints} PTS';
  }

  Widget _buildTeamScore({
    required String label,
    required int score,
    required Color color,
    required bool isLocal,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocal)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                color: isLocal ? const Color(0xFFFFD700) : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
          ),
          child: Center(
            child: Text(
              '$score',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrickDot(int roundIndex) {
    final isSubsequent = state.status == GameStatus.roundFinished && roundIndex == state.nextRoundIndex;
    if (isSubsequent) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.8),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '★',
            style: TextStyle(fontSize: 7, color: Color(0xFFFFD700)),
          ),
        ),
      );
    }

    if (roundIndex >= state.rounds.length) {
      // Not played yet
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white12,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30, width: 1),
        ),
      );
    }

    final round = state.rounds[roundIndex];
    if (round.playedCards.length < state.players.length) {
      // In progress
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber, width: 1.5),
        ),
      );
    }

    if (round.isTied) {
      // Tied trick
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFF9E9E9E),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '=',
            style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final isTeamAWin = round.winnerTeam == Team.teamA;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isTeamAWin ? const Color(0xFF4FC3F7) : const Color(0xFFEF5350),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isTeamAWin ? const Color(0xFF4FC3F7) : const Color(0xFFEF5350))
                .withValues(alpha: 0.6),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

