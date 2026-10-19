import 'package:flutter_test/flutter_test.dart';
import 'package:truco/engine/truco_deck.dart';
import 'package:truco/engine/truco_engine.dart';
import 'package:truco/engine/truco_rules.dart';
import 'package:truco/models/card_model.dart';
import 'package:truco/models/game_state_model.dart';
import 'package:truco/models/player_model.dart';
import 'package:truco/models/round_model.dart';
import 'package:truco/models/truco_enums.dart';

void main() {
  group('Truco Deck & Cards Tests', () {
    test('Deck has 40 cards without 8s, 9s, 10s', () {
      final deck = TrucoDeck.createDeck();
      expect(deck.length, 40);
    });

    test('Rank cycle is correct: 4->5->6->7->Q->J->K->A->2->3->4', () {
      expect(Rank.seven.nextInCycle, Rank.queen);
      expect(Rank.queen.nextInCycle, Rank.jack);
      expect(Rank.jack.nextInCycle, Rank.king);
      expect(Rank.king.nextInCycle, Rank.ace);
      expect(Rank.ace.nextInCycle, Rank.two);
      expect(Rank.two.nextInCycle, Rank.three);
      expect(Rank.three.nextInCycle, Rank.four);
    });
  });

  group('Truco Paulista Rules Tests', () {
    test('Vira 7 makes Q manilha with proper suit hierarchy', () {
      final vira = CardModel(rank: Rank.seven, suit: Suit.ouros);
      final qZap = CardModel(rank: Rank.queen, suit: Suit.paus);
      final qCopas = CardModel(rank: Rank.queen, suit: Suit.copas);
      final qEspadas = CardModel(rank: Rank.queen, suit: Suit.espadas);
      final qOuros = CardModel(rank: Rank.queen, suit: Suit.ouros);
      final threeCard = CardModel(rank: Rank.three, suit: Suit.paus);

      expect(TrucoRules.isPaulistaManilha(qZap, vira), true);
      expect(TrucoRules.isPaulistaManilha(threeCard, vira), false);

      final zapPower = TrucoRules.getCardPower(qZap, TrucoVariant.paulista, vira: vira);
      final copasPower = TrucoRules.getCardPower(qCopas, TrucoVariant.paulista, vira: vira);
      final espadasPower = TrucoRules.getCardPower(qEspadas, TrucoVariant.paulista, vira: vira);
      final ourosPower = TrucoRules.getCardPower(qOuros, TrucoVariant.paulista, vira: vira);
      final threePower = TrucoRules.getCardPower(threeCard, TrucoVariant.paulista, vira: vira);

      expect(zapPower > copasPower, true);
      expect(copasPower > espadasPower, true);
      expect(espadasPower > ourosPower, true);
      expect(ourosPower > threePower, true);
    });

    test('Normal cards tie when same rank regardless of suit in Paulista', () {
      final vira = CardModel(rank: Rank.four, suit: Suit.ouros); // Manilha is 5
      final threeHearts = CardModel(rank: Rank.three, suit: Suit.copas);
      final threeSpades = CardModel(rank: Rank.three, suit: Suit.espadas);

      final p1 = TrucoRules.getCardPower(threeHearts, TrucoVariant.paulista, vira: vira);
      final p2 = TrucoRules.getCardPower(threeSpades, TrucoVariant.paulista, vira: vira);
      expect(p1, equals(p2));
    });

    test('getManilhaName returns correct title for Paulista manilhas', () {
      final vira = CardModel(rank: Rank.three, suit: Suit.ouros); // Manilha is 4
      final zap = CardModel(rank: Rank.four, suit: Suit.paus);
      final copeta = CardModel(rank: Rank.four, suit: Suit.copas);
      final normalCard = CardModel(rank: Rank.two, suit: Suit.paus);

      expect(TrucoRules.getManilhaName(zap, TrucoVariant.paulista, vira: vira), '⚡ ZAP! ⚡');
      expect(TrucoRules.getManilhaName(copeta, TrucoVariant.paulista, vira: vira), '🔥 COPETA! 🔥');
      expect(TrucoRules.getManilhaName(normalCard, TrucoVariant.paulista, vira: vira), isNull);
    });
  });

  group('Truco Mineiro Rules Tests', () {
    test('Fixed manilhas hierarchy is respected', () {
      final zap = CardModel(rank: Rank.four, suit: Suit.paus);
      final seteCopas = CardModel(rank: Rank.seven, suit: Suit.copas);
      final espadilha = CardModel(rank: Rank.ace, suit: Suit.espadas);
      final picafumo = CardModel(rank: Rank.seven, suit: Suit.ouros);
      final anyThree = CardModel(rank: Rank.three, suit: Suit.ouros);

      final pZap = TrucoRules.getCardPower(zap, TrucoVariant.mineiro);
      final pCopas = TrucoRules.getCardPower(seteCopas, TrucoVariant.mineiro);
      final pEsp = TrucoRules.getCardPower(espadilha, TrucoVariant.mineiro);
      final pOuros = TrucoRules.getCardPower(picafumo, TrucoVariant.mineiro);
      final pThree = TrucoRules.getCardPower(anyThree, TrucoVariant.mineiro);

      expect(pZap > pCopas, true);
      expect(pCopas > pEsp, true);
      expect(pEsp > pOuros, true);
      expect(pOuros > pThree, true);
    });
  });

  group('Automatic Teams Assignment', () {
    test('2 players mode assigns 0 to Team A, 1 to Team B', () {
      expect(TrucoRules.getTeamForSeat(0, GameMode.twoPlayers), Team.teamA);
      expect(TrucoRules.getTeamForSeat(1, GameMode.twoPlayers), Team.teamB);
    });

    test('4 players mode alternates A, B, A, B', () {
      expect(TrucoRules.getTeamForSeat(0, GameMode.fourPlayers), Team.teamA);
      expect(TrucoRules.getTeamForSeat(1, GameMode.fourPlayers), Team.teamB);
      expect(TrucoRules.getTeamForSeat(2, GameMode.fourPlayers), Team.teamA);
      expect(TrucoRules.getTeamForSeat(3, GameMode.fourPlayers), Team.teamB);
    });

    test('6 players mode alternates A, B, A, B, A, B', () {
      expect(TrucoRules.getTeamForSeat(0, GameMode.sixPlayers), Team.teamA);
      expect(TrucoRules.getTeamForSeat(1, GameMode.sixPlayers), Team.teamB);
      expect(TrucoRules.getTeamForSeat(2, GameMode.sixPlayers), Team.teamA);
      expect(TrucoRules.getTeamForSeat(3, GameMode.sixPlayers), Team.teamB);
      expect(TrucoRules.getTeamForSeat(4, GameMode.sixPlayers), Team.teamA);
      expect(TrucoRules.getTeamForSeat(5, GameMode.sixPlayers), Team.teamB);
    });
  });

  group('Tie-break (Canguera) Resolution', () {
    test('If round 1 is tied, winner of round 2 wins the hand', () {
      final rounds = [
        const RoundModel(roundIndex: 0, isTied: true),
        const RoundModel(roundIndex: 1, winnerTeam: Team.teamB),
      ];
      final winner = TrucoRules.evaluateHandWinner(rounds);
      expect(winner, Team.teamB);
    });

    test('If round 1 won by A and round 2 tied, Team A wins hand', () {
      final rounds = [
        const RoundModel(roundIndex: 0, winnerTeam: Team.teamA),
        const RoundModel(roundIndex: 1, isTied: true),
      ];
      final winner = TrucoRules.evaluateHandWinner(rounds);
      expect(winner, Team.teamA);
    });

    test('If round 1 won by A, round 2 by B, and round 3 tied, Team A wins', () {
      final rounds = [
        const RoundModel(roundIndex: 0, winnerTeam: Team.teamA),
        const RoundModel(roundIndex: 1, winnerTeam: Team.teamB),
        const RoundModel(roundIndex: 2, isTied: true),
      ];
      final winner = TrucoRules.evaluateHandWinner(rounds);
      expect(winner, Team.teamA);
    });
  });

  group('Full Game Loop Simulation (2, 4 and 6 players)', () {
    test('Starts match with 4 players and deals 3 cards to each', () {
      final players = [
        const PlayerModel(id: '1', name: 'Raphael', seatIndex: 0, team: Team.teamA),
        const PlayerModel(id: '2', name: 'Lucas', seatIndex: 1, team: Team.teamB),
        const PlayerModel(id: '3', name: 'Ana', seatIndex: 2, team: Team.teamA),
        const PlayerModel(id: '4', name: 'Pedro', seatIndex: 3, team: Team.teamB),
      ];

      final state = GameStateModel(
        roomId: 'room_1',
        roomCode: 'TRU123',
        mode: GameMode.fourPlayers,
        variant: TrucoVariant.paulista,
        players: players,
      );

      final started = TrucoEngine.startMatch(state);
      expect(started.status, GameStatus.playing);
      expect(started.players.length, 4);
      for (final p in started.players) {
        expect(p.hand.length, 3);
      }
      expect(started.vira != null, true);
    });

    test('6 players mode successfully deals 3 cards to each player', () {
      final players = List.generate(
        6,
        (i) => PlayerModel(
          id: 'p_$i',
          name: 'Player $i',
          seatIndex: i,
          team: i % 2 == 0 ? Team.teamA : Team.teamB,
        ),
      );

      final state = GameStateModel(
        roomId: 'room_6',
        roomCode: 'TRU666',
        mode: GameMode.sixPlayers,
        variant: TrucoVariant.mineiro,
        players: players,
      );

      final started = TrucoEngine.startMatch(state);
      expect(started.players.length, 6);
      for (final p in started.players) {
        expect(p.hand.length, 3);
      }
      expect(started.handPoints, 2); // Mineiro starts at 2
    });

    test('Round finish enters 5-second interval and advanceAfterInterval moves to next round', () {
      final p1 = PlayerModel(
        id: 'p1',
        name: 'Player 1',
        seatIndex: 0,
        team: Team.teamA,
        hand: [const CardModel(rank: Rank.three, suit: Suit.paus)],
      );
      final p2 = PlayerModel(
        id: 'p2',
        name: 'Player 2',
        seatIndex: 1,
        team: Team.teamB,
        hand: [const CardModel(rank: Rank.four, suit: Suit.ouros)],
      );

      final state = GameStateModel(
        roomId: 'room_interval',
        roomCode: 'TRU555',
        mode: GameMode.twoPlayers,
        variant: TrucoVariant.paulista,
        status: GameStatus.playing,
        players: [p1, p2],
        currentTurnPlayerIndex: 0,
        handRoundStarterPlayerIndex: 0,
        rounds: [const RoundModel(roundIndex: 0)],
        currentRoundIndex: 0,
        vira: const CardModel(rank: Rank.king, suit: Suit.copas), // Manilha is Ace
      );

      // Player 1 plays 3
      final stateAfterP1 = TrucoEngine.playCard(state, 'p1', p1.hand.first);
      expect(stateAfterP1.status, GameStatus.playing);
      expect(stateAfterP1.currentTurnPlayerIndex, 1);

      // Player 2 plays 4 -> 1st round finishes!
      final stateAfterP2 = TrucoEngine.playCard(stateAfterP1, 'p2', p2.hand.first);
      expect(stateAfterP2.status, GameStatus.roundFinished);
      expect(stateAfterP2.status.isInterval, true);
      expect(stateAfterP2.roundWinnerTeam, Team.teamA);
      expect(stateAfterP2.nextRoundIndex, 1);
      expect(stateAfterP2.intervalExpiresAt > DateTime.now().millisecondsSinceEpoch, true);

      // After interval expires: advance to subsequent round
      final advanced = TrucoEngine.advanceAfterInterval(stateAfterP2);
      expect(advanced.status, GameStatus.playing);
      expect(advanced.currentRoundIndex, 1);
    });
  });
}

