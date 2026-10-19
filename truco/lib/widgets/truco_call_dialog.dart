import 'package:flutter/material.dart';
import '../engine/truco_rules.dart';
import '../models/game_state_model.dart';

class TrucoCallBanner extends StatelessWidget {
  final GameStateModel state;
  final String currentUserId;
  final Function({required bool accept, bool raiseInstead}) onRespond;

  const TrucoCallBanner({
    super.key,
    required this.state,
    required this.currentUserId,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.trucoState.isPending) return const SizedBox.shrink();

    final localPlayer = state.getPlayerById(currentUserId);
    final isOpponent = localPlayer != null && localPlayer.team != state.trucoProposerTeam;

    final callLabel = TrucoRules.getRaiseActionLabel(state.pendingTrucoValue);
    final nextRaisePoints = TrucoRules.getNextRaisePoints(state.pendingTrucoValue, state.variant);
    final nextRaiseLabel = TrucoRules.getRaiseActionLabel(nextRaisePoints);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFF880E4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flash_on, color: Color(0xFFFFD700), size: 28),
              const SizedBox(width: 8),
              Text(
                'GRITOU $callLabel',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 2)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.flash_on, color: Color(0xFFFFD700), size: 28),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A mão vai valer ${state.pendingTrucoValue} pontos!',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (isOpponent) ...[
            // Responsive action buttons for opponents
            Row(
              children: [
                // Correr (Refuse)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onRespond(accept: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF424242),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('CORRER', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),

                // Aceitar (Accept)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onRespond(accept: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ACEITAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),

                // Aumentar (Se não atingiu 12 ainda)
                if (state.pendingTrucoValue < 12) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onRespond(accept: true, raiseInstead: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8F00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(nextRaiseLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Aguardando resposta do adversário...',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
