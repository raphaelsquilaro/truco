import 'package:flutter/material.dart';

class QuickChatWidget extends StatelessWidget {
  final Function(String message) onSelectPhrase;

  const QuickChatWidget({super.key, required this.onSelectPhrase});

  static const List<String> phrases = [
    'TRUUUUCO, MARRECO! 🦜',
    'Chama no Zap! ⚡',
    'Se gritar é porque tá com medo! 😱',
    'Caiu na rede é peixe! 🐟',
    'Aqui não, pato! 🦆',
    'Passa o chumbo! 💥',
    'Boa parceiro! 👏',
    'Tem manilha na mesa! 🔥',
    'Vai correr ou vai encarar? 🤠',
    'Hoje é doze sem dó! 🎲',
  ];

  static void show(BuildContext context, Function(String message) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => QuickChatWidget(
        onSelectPhrase: (msg) {
          Navigator.pop(ctx);
          onSelect(msg);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over, color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              const Text(
                'Provocações & Frases de Truco',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: phrases.map((phrase) {
              return ActionChip(
                backgroundColor: const Color(0xFF2C2C2C),
                label: Text(
                  phrase,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white24),
                ),
                onPressed: () => onSelectPhrase(phrase),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

