import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1D0F),
        title: const Text('Regras do Truco Brasileiro', style: TextStyle(color: Colors.white)),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildVariantSection(
            title: 'TRUCO PAULISTA',
            subtitle: 'Vira e Manilhas Dinâmicas',
            icon: Icons.flash_on,
            color: const Color(0xFFFFD700),
            content: [
              '• Baralho de 40 cartas (sem 8, 9 e 10).',
              '• Uma carta é virada na mesa: o "Vira".',
              '• A Manilha é a carta de valor imediatamente seguinte ao Vira no ciclo: 4 ➔ 5 ➔ 6 ➔ 7 ➔ Q ➔ J ➔ K ➔ A ➔ 2 ➔ 3 ➔ 4.',
              '• As manilhas são desempatadas pelos 4 naipes (do mais forte ao mais fraco):\n   1º Paus (Zap) ♣\n   2º Copas (Copeta) ♥\n   3º Espadas (Espadilha) ♠\n   4º Ouros (Picafumo) ♦',
              '• Cartas comuns empatam se tiverem o mesmo número, independente do naipe.',
              '• Pontuação: Mão normal vale 1 ponto. Aumentos: Truco (3) ➔ Seis (6) ➔ Nove (9) ➔ Doze (12).',
              '• Mão de 11: Quando o time chega a 11 pontos, pode ver a mão do parceiro antes de aceitar jogar (valendo 3 pontos) ou correr (dando 1 ponto ao adversário). Truco proibido.',
            ],
          ),
          const SizedBox(height: 16),
          _buildVariantSection(
            title: 'TRUCO MINEIRO',
            subtitle: 'Manilhas Velhas (Fixas)',
            icon: Icons.shield,
            color: const Color(0xFFE57373),
            content: [
              '• As manilhas são FIXAS em todas as mãos do jogo:\n   1º 4 de Paus (Zap) ♣ (A maior carta do jogo)\n   2º 7 de Copas ♥\n   3º Ás de Espadas (Espadilha) ♠\n   4º 7 de Ouros (Picafumo) ♦',
              '• Demais cartas seguem a ordem: 3 > 2 > Ás (outros naipes) > Rei > Valete > Dama > 7 (outros) > 6 > 5 > 4 (outros).',
              '• Pontuação: A mão normal vale 2 pontos. Aumentos escalam para 4, 8 e 12 pontos.',
              '• Mão de 10: Ocorre quando a equipe chega a 10 pontos.',
            ],
          ),
          const SizedBox(height: 16),
          _buildVariantSection(
            title: 'CRITÉRIOS DE DESEMPATE (CANGUERA)',
            subtitle: 'Melhor de 3 Rodadas',
            icon: Icons.balance,
            color: const Color(0xFF64B5F6),
            content: [
              '• Empate na 1ª rodada: Quem vencer a 2ª rodada leva a mão.',
              '• Vitória na 1ª e empate na 2ª: Quem venceu a 1ª leva a mão.',
              '• Empate na 1ª e na 2ª: Quem vencer a 3ª leva a mão.',
              '• Cada time venceu uma rodada e empatou a 3ª: O time que venceu a 1ª rodada é o campeão da mão.',
              '• Empate em todas as 3 rodadas: Ninguém pontua, passa o baralho para o próximo carteador.',
            ],
          ),
          const SizedBox(height: 16),
          _buildVariantSection(
            title: 'MODALIDADES & EQUIPES',
            subtitle: '2, 4 ou 6 Jogadores com Equipes Automáticas',
            icon: Icons.groups,
            color: const Color(0xFF81C784),
            content: [
              '• 2 Jogadores (1x1): Jogador 1 (Time A) contra Jogador 2 (Time B).',
              '• 4 Jogadores (2x2): Parceiros sentam alternados (Norte/Sul vs Leste/Oeste). Assentos 1 e 3 são Time A; 2 e 4 são Time B.',
              '• 6 Jogadores (3x3): 3 contra 3 com assentos alternados em círculo ao redor da mesa oval.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF142417),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          ...content.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

