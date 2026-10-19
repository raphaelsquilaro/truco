import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/game_state_model.dart';
import '../models/truco_enums.dart';

class RoundIntervalBanner extends StatefulWidget {
  final GameStateModel state;

  const RoundIntervalBanner({super.key, required this.state});

  @override
  State<RoundIntervalBanner> createState() => _RoundIntervalBannerState();
}

class _RoundIntervalBannerState extends State<RoundIntervalBanner> {
  Timer? _timer;
  int _secondsLeft = 5;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    if (!mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = ((widget.state.intervalExpiresAt - now) / 1000).ceil();
    final remaining = diff.clamp(0, 5);
    if (remaining != _secondsLeft) {
      setState(() {
        _secondsLeft = remaining;
      });
    }
  }

  @override
  void didUpdateWidget(RoundIntervalBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.intervalExpiresAt != widget.state.intervalExpiresAt) {
      _calculateRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isHandFinished = state.status == GameStatus.handFinished;
    final isMatchFinished = state.status == GameStatus.matchFinished;

    final roundIndex = state.currentRoundIndex + 1;
    final nextRoundNumber = isHandFinished ? 1 : state.nextRoundIndex + 1;

    String outcomeTitle;
    IconData outcomeIcon;
    Color outcomeColor;

    if (isMatchFinished) {
      outcomeTitle = 'PARABÉNS! ${state.matchWinner?.label ?? "TIME"} VENCEU A PARTIDA!';
      outcomeIcon = Icons.emoji_events;
      outcomeColor = const Color(0xFFFFD700);
    } else if (isHandFinished) {
      outcomeTitle = '${state.handWinner?.label ?? "TIME"} LEVOU A MÃO (${state.handPoints} PTS)!';
      outcomeIcon = Icons.check_circle;
      outcomeColor = const Color(0xFF4CAF50);
    } else if (state.isRoundTied) {
      outcomeTitle = 'RODADA EMPATADA (CANGUERA)!';
      outcomeIcon = Icons.balance;
      outcomeColor = const Color(0xFFFFB300);
    } else {
      outcomeTitle = '${state.roundWinnerTeam?.label ?? "TIME"} FEZ A $roundIndexª RODADA!';
      outcomeIcon = Icons.stars;
      outcomeColor = state.roundWinnerTeam == Team.teamA
          ? const Color(0xFF4FC3F7)
          : const Color(0xFFEF5350);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B3620), Color(0xFF0F1E12)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD700), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 20,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Outcome
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(outcomeIcon, color: outcomeColor, size: 26)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 500.ms),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    outcomeTitle,
                    style: TextStyle(
                      color: outcomeColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            if (state.roundWinningPlayerName != null && !state.isRoundTied) ...[
              const SizedBox(height: 4),
              Text(
                'Carta vencedora de ${state.roundWinningPlayerName}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],

            const Divider(color: Colors.white24, height: 18),

            // Destaque para a Partida e Placar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Time A: ${state.scoreTeamA} pts',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Text('x', style: TextStyle(color: Colors.white38)),
                  Text(
                    'Time B: ${state.scoreTeamB} pts',
                    style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // DESTAQUE PARA A RODADA SUBSEQUENTE
            if (!isMatchFinished) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF8F00).withValues(alpha: 0.25),
                      const Color(0xFFFFD700).withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          isHandFinished
                              ? '🎯 DESTAQUE: NOVA MÃO DE TRUCO'
                              : '🎯 DESTAQUE: $nextRoundNumberª RODADA A SEGUIR!',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubsequentRoundTip(state, isHandFinished, nextRoundNumber),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (state.nextStarterPlayerName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Começa com: ${state.nextStarterPlayerName}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 2000.ms, color: Colors.amber.withValues(alpha: 0.3)),

              const SizedBox(height: 14),

              // 5-second interval progress & countdown timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: _secondsLeft / 5.0,
                      strokeWidth: 2.5,
                      color: const Color(0xFFFFD700),
                      backgroundColor: Colors.white24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Intervalo: próxima rodada em ${_secondsLeft}s...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: 350.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 250.ms);
  }

  String _getSubsequentRoundTip(GameStateModel state, bool isHandFinished, int nextRound) {
    if (isHandFinished) {
      return 'Novo carteador e nova distribuição de cartas!';
    }
    if (state.isRoundTied) {
      return 'Rodada decisiva! Quem vencer a $nextRoundª rodada leva a mão!';
    }
    if (nextRound == 2) {
      return 'Atenção: Se empatar a 2ª rodada, quem fez a 1ª ganha a mão!';
    }
    if (nextRound == 3) {
      return 'Última vaza! O grande tira-teima para decidir a mão!';
    }
    return 'Prepare suas melhores cartas!';
  }
}

