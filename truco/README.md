# 🂠 Truco Amigos (Flutter Mobile App)

Aplicativo móvel desenvolvido em **Flutter** para jogar Truco online com amigos, com suporte completo às regras tradicionais brasileiras nas variantes **Truco Paulista** e **Truco Mineiro**, modos para **2, 4 e 6 jogadores**, salas privadas por código e integração **Firebase**.

---

## 🎯 Funcionalidades Principais

1. **Variantes do Truco Tradicional**:
   - **Truco Paulista**:
     - O "Vira" define a manilha da rodada (a carta de valor imediatamente superior no ciclo: `4 ➔ 5 ➔ 6 ➔ 7 ➔ Q ➔ J ➔ K ➔ A ➔ 2 ➔ 3 ➔ 4`).
     - Desempate das manilhas pela hierarquia oficial de 4 naipes:
       1. **Paus / Zap** (♣) - mais forte
       2. **Copas / Copeta** (♥)
       3. **Espadas / Espadilha** (♠)
       4. **Ouros / Picafumo** (♦)
     - Cartas normais não-manilhas empatam se tiverem o mesmo valor, independente do naipe.
     - Escalação de apostas: **Truco (3) ➔ Seis (6) ➔ Nove (9) ➔ Doze (12)**.
     - **Mão de 11**: ativa quando uma equipe atinge 11 pontos. A dupla decide se joga valendo 3 pontos ou corre dando 1 ponto aos oponentes. Truco proibido.
     - **Mão de Ferro**: quando ambas equipes têm 11 pontos, joga-se no escuro.
   - **Truco Mineiro**:
     - Manilhas Fixas ("Manilhas Velhas"):
       1. **4 de Paus (Zap)** (♣)
       2. **7 de Copas** (♥)
       3. **Ás de Espadas (Espadilha)** (♠)
       4. **7 de Ouros (Picafumo)** (♦)
     - Escalação de apostas tradicional: mão inicial de 2 pontos ➔ 4 ➔ 8 ➔ 12 pontos.
     - **Mão de 10**: ativa quando uma equipe alcança 10 pontos.

2. **Modalidades de Jogadores & Equipes Automáticas**:
   - **2 Jogadores (1x1)**: Jogador 1 (Time A) vs Jogador 2 (Time B).
   - **4 Jogadores (2x2)**: Assentos 1 e 3 (Time A) vs Assentos 2 e 4 (Time B) posicionados em lados opostos da mesa.
   - **6 Jogadores (3x3)**: 3 contra 3 com assentos alternados em círculo ao redor da mesa oval.

3. **Multiplayer Online em Tempo Real**:
   - **Salas Privadas por Código**: geração de códigos únicos alfanuméricos de 6 caracteres (ex: `TRU482`).
   - Entrada rápida digitando o código da sala.
   - Lobby com distribuição automática de assentos e equipes.
   - Sincronização em tempo real das jogadas, apostas e placar via **Firebase Cloud Firestore**.
   - **Modo Híbrido Resiliente**: caso o projeto ainda não possua o `google-services.json` configurado na máquina local, o aplicativo utiliza repositório em memória com Streams, garantindo execução perfeita sem travamentos.
   - Suporte a **Bots com IA**: o Dono da Sala pode preencher vagas abertas com bots ou treinar offline.

4. **Autenticação de Usuários**:
   - **Tela de Login**: com e-mail/senha e opção de acesso rápido como **Convidado**.
   - **Tela de Cadastro**: com apelido na mesa, e-mail e senha.
   - Integração com **Firebase Authentication**.

5. **Interface Imersiva de Jogo & Intervalos de Rodada**:
   - **Intervalo de 5 Segundos entre Rodadas**: Ao término de cada rodada/vaza, o jogo pausa por 5 segundos com contagem regressiva animada, mantendo as cartas na mesa para que todos vejam as jogadas e o resultado.
   - **Destaque da Rodada Subsequente**: Ao final de cada rodada, é exibido quem ganhou a vaza/partida e um spotlight brilhante anunciando a rodada seguinte (dicas táticas, quem é o carteador/iniciador e marcador pulsante no placar).
   - **Carta Vencedora com Coroa**: A carta que fez a vaza recebe a insígnia dourada `👑 VENCEU A VAZA`.
   - Mesa de feltro verde com bordas de madeira e detalhes em dourado.
   - Cartas brasileiras ilustradas com física de impacto e destaques especiais de Manilha (ondas de choque e tremor de mesa).
   - Opção de **Jogar Carta Oculta (coberta / passar por baixo)** a partir da 2ª vaza.
   - Gritos animados de **TRUCO!**, **SEIS!**, **NOVE!**, **DOZE!**.
   - Banner de resposta dinâmica: **ACEITAR**, **CORRER** ou **AUMENTAR**.
   - Placar em tempo real com histórico visual das 3 rodadas da mão.
   - **Provocações e Chat Rápido** com frases clássicas do Truco brasileiro.

---

## 🏗️ Arquitetura do Projeto

```
lib/
├── engine/
│   ├── bot_ai.dart          # Inteligência artificial para treino e preenchimento de vagas
│   ├── truco_deck.dart      # Baralho tradicional de 40 cartas (sem 8, 9 e 10)
│   ├── truco_engine.dart    # Máquina de estados do jogo, rodadas, pontuação e apostas
│   └── truco_rules.dart     # Regras de Paulista e Mineiro, desempates (canguera) e naipes
├── models/
│   ├── card_model.dart      # Modelo da carta (Rank, Suit, FaceDown)
│   ├── game_state_model.dart# Estado imutável e serializável para Firestore
│   ├── player_model.dart    # Modelo de jogador e assento
│   ├── round_model.dart     # Vazas/rodadas individuais da mão
│   └── truco_enums.dart     # GameMode, TrucoVariant, Team, TrucoCallState
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Tela de Login com e-mail/senha e convidado
│   │   └── register_screen.dart # Tela de Cadastro
│   ├── game/
│   │   └── game_table_screen.dart # Mesa oval interativa de 2, 4 e 6 jogadores
│   ├── home/
│   │   ├── home_screen.dart     # Menu principal (Criar Sala, Entrar, Treino, Regras)
│   │   └── rules_screen.dart    # Guia interativo das regras de Truco
│   └── room/
│       ├── create_room_dialog.dart # Criação de salas personalizadas
│       ├── join_room_dialog.dart   # Entrada via código
│       └── lobby_screen.dart       # Sala de espera com assentos das equipes
├── services/
│   ├── auth_service.dart     # Firebase Auth com fallback resiliente
│   ├── firebase_service.dart # Inicialização segura do Firebase
│   └── room_service.dart     # Multiplayer em tempo real com Firestore
└── widgets/
    ├── playing_card_widget.dart # Carta visual renderizada com destaque de manilha
    ├── quick_chat_widget.dart   # Provocações clássicas ("TRUUUCO, MARRECO!", etc.)
    ├── score_board_widget.dart  # Placar da partida e bolinhas de vazas
    └── truco_call_dialog.dart   # Diálogo de resposta de aposta
```

---

## 🧪 Testes Automatizados

O projeto conta com suíte de testes unitários cobrindo o baralho, a hierarquia de cartas no Paulista e Mineiro, a lógica de desempates (canguera) e o loop de partidas para 2, 4 e 6 jogadores:

```bash
flutter test
```

## 🚀 Como Executar

1. Obtenha as dependências:
   ```bash
   flutter pub get
   ```
2. Execute o aplicativo:
   ```bash
   flutter run
   ```
