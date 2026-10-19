import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/game_state_model.dart';
import '../../models/player_model.dart';
import '../../models/truco_enums.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../game/game_table_screen.dart';

class LobbyScreen extends StatelessWidget {
  final String roomId;

  const LobbyScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final roomService = context.watch<RoomService>();
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    return StreamBuilder<GameStateModel>(
      stream: roomService.streamRoom(roomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D2814),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          );
        }

        final state = snapshot.data!;

        // Automatically navigate into the game table when status is playing
        if (state.status == GameStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GameTableScreen(roomId: state.roomId),
              ),
            );
          });
        }

        final localPlayer = state.getPlayerById(currentUser?.id ?? '');
        final isHost = localPlayer?.isHost ?? false;
        final maxPlayers = state.mode.maxPlayers;
        final isFull = state.players.length >= maxPlayers;

        return Scaffold(
          backgroundColor: const Color(0xFF0D2814),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A1D0F),
            title: const Text('Sala de Espera (Lobby)', style: TextStyle(color: Colors.white)),
            elevation: 2,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Room Code Banner
                  _buildRoomCodeCard(context, state.roomCode),

                  const SizedBox(height: 16),

                  // Room Details Card
                  _buildRoomDetailsCard(state),

                  const SizedBox(height: 20),

                  // Seats & Automatic Teams List
                  Text(
                    'JOGADORES NA MESA (${state.players.length}/$maxPlayers)',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...List.generate(maxPlayers, (index) {
                    final player = index < state.players.length ? state.players[index] : null;
                    final team = index % 2 == 0 ? Team.teamA : Team.teamB;

                    return _buildSeatTile(
                      context,
                      seatIndex: index,
                      team: team,
                      player: player,
                      isHost: isHost,
                      onAddBot: () async {
                        try {
                          await roomService.addBot(state.roomId);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        }
                      },
                    );
                  }),

                  const SizedBox(height: 24),

                  // Start Match Button
                  if (isHost)
                    ElevatedButton(
                      onPressed: isFull
                          ? () async {
                              HapticFeedback.heavyImpact();
                              await roomService.startMatch(state.roomId);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: Text(
                        isFull
                            ? 'INICIAR PARTIDA'
                            : 'AGUARDANDO JOGADORES (${state.players.length}/$maxPlayers)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Aguardando o Dono da Sala iniciar a partida...',
                          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomCodeCard(BuildContext context, String roomCode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E6B34), Color(0xFF0F401C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'CÓDIGO DA SALA PRIVADA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                roomCode,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy, color: Color(0xFFFFD700), size: 28),
                tooltip: 'Copiar Código',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: roomCode));
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código da sala copiado! Compartilhe com seus amigos.'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Passe este código para seus amigos entrarem',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDetailsCard(GameStateModel state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF142417),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailItem(Icons.style, 'Regras', state.variant.label),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildDetailItem(Icons.people, 'Modalidade', state.mode.label),
          Container(width: 1, height: 30, color: Colors.white24),
          _buildDetailItem(Icons.flag, 'Meta', '12 Pontos'),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String val) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 20),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSeatTile(
    BuildContext context, {
    required int seatIndex,
    required Team team,
    required PlayerModel? player,
    required bool isHost,
    required VoidCallback onAddBot,
  }) {
    final isTeamA = team == Team.teamA;
    final teamColor = isTeamA ? const Color(0xFF1976D2) : const Color(0xFFD32F2F);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16251A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player != null ? teamColor.withValues(alpha: 0.6) : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Team badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: teamColor),
            ),
            child: Text(
              team.label,
              style: TextStyle(
                color: teamColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),

          if (player != null) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF2C3E2F),
              child: Text(player.avatar, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (player.isHost) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                      ],
                      if (player.isBot) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade900,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('BOT', style: TextStyle(color: Colors.white, fontSize: 9)),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'Assento ${seatIndex + 1}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
          ] else ...[
            const Expanded(
              child: Text(
                'Vaga Aberta (Aguardando amigo entrar...)',
                style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
            if (isHost)
              OutlinedButton.icon(
                onPressed: onAddBot,
                icon: const Icon(Icons.smart_toy, size: 16, color: Color(0xFFFFD700)),
                label: const Text('Preencher com Bot', style: TextStyle(fontSize: 11, color: Color(0xFFFFD700))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFD700)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
