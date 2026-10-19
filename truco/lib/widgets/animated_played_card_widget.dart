import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/round_model.dart';
import '../models/truco_enums.dart';
import 'playing_card_widget.dart';

class AnimatedPlayedCardWidget extends StatelessWidget {
  final PlayedCard playedCard;
  final bool isManilha;
  final String? manilhaLabel;
  final bool isLatest;
  final bool isRoundWinner;
  final double cardWidth;
  final double cardHeight;

  const AnimatedPlayedCardWidget({
    super.key,
    required this.playedCard,
    this.isManilha = false,
    this.manilhaLabel,
    this.isLatest = false,
    this.isRoundWinner = false,
    this.cardWidth = 56,
    this.cardHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    final isTeamA = playedCard.team == Team.teamA;
    // Compute organic tilt based on seat index (-6 deg to +6 deg)
    final tiltAngles = [-0.08, 0.06, -0.05, 0.07, -0.04, 0.05];
    final angle = tiltAngles[playedCard.seatIndex % tiltAngles.length];

    Widget cardWidget = Transform.rotate(
      angle: angle,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Golden aura glow if Manilha
          if (isManilha)
            Container(
              width: cardWidth + 12,
              height: cardHeight + 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.85),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 26,
                    spreadRadius: 8,
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 800.ms,
                  curve: Curves.easeInOut,
                ),

          // The Card Widget
          PlayingCardWidget(
            card: playedCard.card,
            width: cardWidth,
            height: cardHeight,
            isManilha: isManilha,
            isPlayable: false,
          ),

          // Glowing Manilha Pin Badge
          if (isManilha && manilhaLabel != null)
            Positioned(
              top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8F00), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  manilhaLabel!,
                  style: const TextStyle(
                    color: Color(0xFF2E1C00),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1.0, 1.0),
                    duration: 300.ms,
                    curve: Curves.elasticOut,
                  ),
            ),
          // Round Winner Crown Badge
          if (isRoundWinner)
            Positioned(
              top: -16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('👑', style: TextStyle(fontSize: 10)),
                    SizedBox(width: 3),
                    Text(
                      'VENCEU A VAZA',
                      style: TextStyle(
                        color: Color(0xFF2E1C00),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.08, 1.08),
                    duration: 600.ms,
                  ),
            ),
        ],
      ),
    );

    // Apply entrance slam animation if it was just played
    if (isLatest) {
      cardWidget = cardWidget
          .animate()
          .scale(
            begin: const Offset(1.5, 1.5),
            end: const Offset(1.0, 1.0),
            duration: 280.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 150.ms);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        cardWidget,
        const SizedBox(height: 6),
        // Player badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isTeamA ? const Color(0xFF0D47A1) : const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isManilha ? const Color(0xFFFFD700) : Colors.white24,
              width: isManilha ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isManilha)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(Icons.flash_on, color: Color(0xFFFFD700), size: 10),
                ),
              Text(
                playedCard.playerName.length > 8
                    ? '${playedCard.playerName.substring(0, 7)}…'
                    : playedCard.playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
