import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ManilhaBurstWidget extends StatelessWidget {
  final String manilhaName;
  final String playerName;
  final VoidCallback onDismissed;

  const ManilhaBurstWidget({
    super.key,
    required this.manilhaName,
    required this.playerName,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Shockwave 1: Golden expanding ring
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 4),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(3.2, 3.2),
                  duration: 650.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeOut(duration: 650.ms),

            // Shockwave 2: Electric cyan/purple outer ring
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00E5FF), width: 2),
              ),
            )
                .animate(delay: 80.ms)
                .scale(
                  begin: const Offset(0.4, 0.4),
                  end: const Offset(3.8, 3.8),
                  duration: 750.ms,
                  curve: Curves.easeOutQuad,
                )
                .fadeOut(duration: 750.ms),

            // Center Explosive Banner
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8F00), Color(0xFFFFD700), Color(0xFFFF6F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFF2E1C00), size: 28)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .rotate(begin: -0.1, end: 0.1, duration: 250.ms),
                      const SizedBox(width: 8),
                      Text(
                        manilhaName,
                        style: const TextStyle(
                          color: Color(0xFF2E1C00),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.flash_on, color: Color(0xFF2E1C00), size: 28)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .rotate(begin: 0.1, end: -0.1, duration: 250.ms),
                    ],
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1.0, 1.0),
                      duration: 350.ms,
                      curve: Curves.elasticOut,
                    )
                    .then(delay: 1400.ms)
                    .fadeOut(duration: 300.ms),

                const SizedBox(height: 6),

                // Player announcement sub-tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700), width: 1),
                  ),
                  child: Text(
                    '$playerName jogou na mesa!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .then(delay: 1400.ms)
                    .fadeOut(duration: 300.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

