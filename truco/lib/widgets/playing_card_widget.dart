import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/card_model.dart';

class PlayingCardWidget extends StatelessWidget {
  final CardModel card;
  final bool isSelected;
  final bool isPlayable;
  final bool isManilha;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isPlayable = true,
    this.isManilha = false,
    this.onTap,
    this.width = 72,
    this.height = 104,
  });

  @override
  Widget build(BuildContext context) {
    if (card.isFaceDown) {
      return _buildCardBack();
    }

    Widget cardBody = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, isSelected ? -16 : 0, 0),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isManilha
                ? const Color(0xFFFFD700)
                : isSelected
                    ? Colors.amber
                    : const Color(0xFFCCCCCC),
            width: isManilha ? 2.5 : isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isManilha
                  ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: isManilha ? 8 : (isSelected ? 10 : 4),
              offset: Offset(0, isSelected ? 6 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Top-left rank and suit
            Positioned(
              top: 4,
              left: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.rank.symbol,
                    style: TextStyle(
                      fontSize: width * 0.22,
                      fontWeight: FontWeight.bold,
                      color: card.suit.color,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    card.suit.symbol,
                    style: TextStyle(
                      fontSize: width * 0.20,
                      color: card.suit.color,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            // Center large suit icon
            Center(
              child: Text(
                card.suit.symbol,
                style: TextStyle(
                  fontSize: width * 0.45,
                  color: card.suit.color.withValues(alpha: 0.9),
                  height: 1.0,
                ),
              ),
            ),

            // Bottom-right rank and suit (inverted)
            Positioned(
              bottom: 4,
              right: 6,
              child: RotatedBox(
                quarterTurns: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.rank.symbol,
                      style: TextStyle(
                        fontSize: width * 0.22,
                        fontWeight: FontWeight.bold,
                        color: card.suit.color,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      card.suit.symbol,
                      style: TextStyle(
                        fontSize: width * 0.20,
                        color: card.suit.color,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Golden badge if Manilha
            if (isManilha)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: const Text(
                    '★ MANILHA',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2E1C00),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );

    if (isManilha) {
      cardBody = cardBody
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 1800.ms,
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
          );
    }

    return GestureDetector(
      onTap: isPlayable ? onTap : null,
      child: cardBody,
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFD700), width: 1),
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              colors: [Color(0xFF800000), Color(0xFF5A0000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.shield,
              color: Color(0xFFFFD700),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

