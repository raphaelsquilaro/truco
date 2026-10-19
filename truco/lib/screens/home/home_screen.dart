import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/truco_enums.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../game/game_table_screen.dart';
import '../room/create_room_dialog.dart';
import '../room/join_room_dialog.dart';
import 'rules_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D2814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D0F),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1E3A24),
              child: Text(user?.avatar ?? '🤠', style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Truqueiro',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.isAnonymous ?? false ? 'Convidado' : (user?.email ?? 'Online'),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFFFFD700)),
            tooltip: 'Regras do Truco',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RulesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sair da Conta',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Banner with Game Variants Highlights
              _buildWelcomeBanner(),

              const SizedBox(height: 24),

              const Text(
                'ESCOLHA COMO JOGAR',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Action 1: Criar Sala Privada
              _buildActionCard(
                context,
                title: 'Criar Sala Privada',
                subtitle: 'Gere um código para 2, 4 ou 6 amigos jogarem online.',
                icon: Icons.add_circle,
                gradient: const [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                borderColor: const Color(0xFFFFD700),
                onTap: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (_) => const CreateRoomDialog(),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Action 2: Entrar na Sala com Código
              _buildActionCard(
                context,
                title: 'Entrar com Código',
                subtitle: 'Tem o código de uma sala privada? Digite e sente na mesa.',
                icon: Icons.vpn_key,
                gradient: const [Color(0xFF1565C0), Color(0xFF0D47A1)],
                borderColor: const Color(0xFF64B5F6),
                onTap: () {
                  HapticFeedback.lightImpact();
                  showDialog(
                    context: context,
                    builder: (_) => const JoinRoomDialog(),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Action 3: Treino Rápido Offline com Bots
              _buildActionCard(
                context,
                title: 'Jogar com Bots (Treino)',
                subtitle: 'Partida instantânea em 1x1, 2x2 ou 3x3 contra a IA.',
                icon: Icons.smart_toy,
                gradient: const [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                borderColor: const Color(0xFFBA68C8),
                onTap: () => _startInstantBotMatch(context),
              ),

              const SizedBox(height: 12),

              // Action 4: Regras do Jogo
              _buildActionCard(
                context,
                title: 'Regras & Manilhas',
                subtitle: 'Consulte a hierarquia do Paulista (Vira) e Mineiro (Velhas).',
                icon: Icons.menu_book,
                gradient: const [Color(0xFF424242), Color(0xFF212121)],
                borderColor: Colors.white24,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RulesScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [Color(0xFF1E6B34), Color(0xFF0B3014)],
          radius: 0.9,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.style, color: Color(0xFFFFD700), size: 36),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRUCO AMIGOS',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Equipes automáticas, salas privadas e regras oficiais brasileiras!',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _startInstantBotMatch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF142417),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        GameMode mode = GameMode.fourPlayers;
        TrucoVariant variant = TrucoVariant.paulista;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Treino com Bots - Configuração',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mode selection
                  Wrap(
                    spacing: 8,
                    children: GameMode.values.map((m) {
                      final sel = mode == m;
                      return ChoiceChip(
                        label: Text(m.label),
                        selected: sel,
                        selectedColor: const Color(0xFF2E7D32),
                        backgroundColor: const Color(0xFF243828),
                        labelStyle: TextStyle(
                          color: sel ? Colors.white : Colors.white70,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => mode = m);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // Variant selection
                  Row(
                    children: TrucoVariant.values.map((v) {
                      final sel = variant == v;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            onPressed: () => setModalState(() => variant = v),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: sel ? const Color(0xFF2E7D32) : Colors.transparent,
                              side: BorderSide(
                                color: sel ? const Color(0xFFFFD700) : Colors.white24,
                              ),
                            ),
                            child: Text(
                              v.label,
                              style: TextStyle(
                                color: sel ? Colors.white : Colors.white70,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final auth = context.read<AuthService>();
                      final roomService = context.read<RoomService>();

                      // Create room
                      final state = await roomService.createRoom(
                        mode: mode,
                        variant: variant,
                        hostUser: auth.currentUser!,
                      );

                      // Fill remaining seats with bots
                      final botsNeeded = mode.maxPlayers - 1;
                      for (int i = 0; i < botsNeeded; i++) {
                        await roomService.addBot(state.roomId);
                      }

                      // Start match
                      await roomService.startMatch(state.roomId);

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameTableScreen(roomId: state.roomId),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('INICIAR PARTIDA COM BOTS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

