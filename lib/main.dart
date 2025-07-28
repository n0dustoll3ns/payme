import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'domain/balance_calculator.dart';
import 'domain/participant.dart';
import 'domain/transaction.dart';

void main() {
  // Тест расчета балансов
  _testBalanceCalculation();

  runApp(const MyApp());
}

void _testBalanceCalculation() {
  try {
    // Создаем тестовых участников
    final alice = Participant(name: 'Alice');
    final bob = Participant(name: 'Bob');
    final charlie = Participant(name: 'Charlie');

    // Создаем тестовую транзакцию: Alice заплатила 300₽ за всех
    final transaction = Transaction(
      id: 'test_transaction',
      payerId: alice.id,
      totalAmount: 300.0, // Alice заплатила 300₽
      participantAmounts: {
        alice.id: 100.0, // Alice потребила на 100₽
        bob.id: 100.0, // Bob потребил на 100₽
        charlie.id: 100.0, // Charlie потребил на 100₽
      },
    );

    final participants = [alice, bob, charlie];
    final transactions = [transaction];

    // Рассчитываем балансы
    final balances = BalanceCalculator.calculateBalances(participants, transactions);
    final debts = BalanceCalculator.calculateDebts(participants, transactions);

    print('=== Тест расчета балансов ===');
    print('Alice заплатила: 300₽, потребила: 100₽');
    print('Bob потребил: 100₽');
    print('Charlie потребил: 100₽');
    print('');
    print('Балансы:');
    print('Alice: ${balances[alice.id]}₽ (должна получить ${balances[alice.id]! - 100}₽ за вычетом потребления)');
    print('Bob: ${balances[bob.id]}₽ (должен отдать)');
    print('Charlie: ${balances[charlie.id]}₽ (должен отдать)');
    print('');
    print('Долги:');
    for (final debt in debts) {
      final fromName = participants.firstWhere((p) => p.id == debt.fromId).name;
      final toName = participants.firstWhere((p) => p.id == debt.toId).name;
      print('$fromName → $toName: ${debt.amount}₽');
    }

    // Проверяем правильность
    final aliceBalance = balances[alice.id]!;
    final bobBalance = balances[bob.id]!;
    final charlieBalance = balances[charlie.id]!;

    print('');
    print('Проверка:');
    print('Alice должна получить: 300₽ - 100₽ = 200₽ ✅ ${aliceBalance == 200.0 ? "ПРАВИЛЬНО" : "ОШИБКА"}');
    print('Bob должен отдать: 100₽ ✅ ${bobBalance == -100.0 ? "ПРАВИЛЬНО" : "ОШИБКА"}');
    print('Charlie должен отдать: 100₽ ✅ ${charlieBalance == -100.0 ? "ПРАВИЛЬНО" : "ОШИБКА"}');
    print(
      'Общая сумма балансов должна быть 0: ${aliceBalance + bobBalance + charlieBalance}₽ ✅ ${(aliceBalance + bobBalance + charlieBalance).abs() < 0.01 ? "ПРАВИЛЬНО" : "ОШИБКА"}',
    );
  } catch (e) {
    print('❌ Ошибка тестирования: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayMe - Подсчёт расходов',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E1E1E), elevation: 0),
        cardTheme: const CardThemeData(
          color: Color(0xFF2D2D2D),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
