import 'participant.dart';
import 'transaction.dart';

class BalanceCalculator {
  /// Рассчитывает балансы для всех участников
  /// Возвращает Map<participantId, balance> где:
  /// - положительное значение = участник должен получить деньги
  /// - отрицательное значение = участник должен отдать деньги
  static Map<String, double> calculateBalances(List<Participant> participants, List<Transaction> transactions) {
    final Map<String, double> balances = {};

    // Инициализируем балансы всех участников
    for (final participant in participants) {
      balances[participant.id] = 0.0;
    }

    // Рассчитываем балансы на основе транзакций
    for (final transaction in transactions) {
      // Плательщик заплатил totalAmount, поэтому должен получить эту сумму обратно
      balances[transaction.payerId] = (balances[transaction.payerId] ?? 0.0) + transaction.totalAmount;

      // Участники потребили свои доли, поэтому должны отдать эти суммы
      for (final entry in transaction.participantAmounts.entries) {
        final participantId = entry.key;
        final amount = entry.value;
        balances[participantId] = (balances[participantId] ?? 0.0) - amount;
      }
    }

    return balances;
  }

  /// Рассчитывает долги между участниками
  /// Возвращает список долгов, отсортированных по сумме (от больших к меньшим)
  static List<Debt> calculateDebts(List<Participant> participants, List<Transaction> transactions) {
    final balances = calculateBalances(participants, transactions);
    final debts = <Debt>[];

    // Создаем список участников с положительными и отрицательными балансами
    final creditors = <String, double>{}; // те, кто должен получить
    final debtors = <String, double>{}; // те, кто должен отдать

    for (final entry in balances.entries) {
      if (entry.value > 0.01) {
        // допускаем небольшую погрешность
        creditors[entry.key] = entry.value;
      } else if (entry.value < -0.01) {
        debtors[entry.key] = -entry.value; // делаем положительным для удобства
      }
    }

    // Сортируем по убыванию суммы
    final sortedCreditors = creditors.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final sortedDebtors = debtors.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Распределяем долги
    int creditorIndex = 0;
    int debtorIndex = 0;

    while (creditorIndex < sortedCreditors.length && debtorIndex < sortedDebtors.length) {
      final creditor = sortedCreditors[creditorIndex];
      final debtor = sortedDebtors[debtorIndex];

      final amount = creditor.value < debtor.value ? creditor.value : debtor.value;

      if (amount > 0.01) {
        // пропускаем очень маленькие суммы
        debts.add(Debt(fromId: debtor.key, toId: creditor.key, amount: amount));

        // Обновляем оставшиеся суммы
        if (creditor.value <= debtor.value) {
          creditorIndex++;
          sortedDebtors[debtorIndex] = MapEntry(debtor.key, debtor.value - creditor.value);
        } else {
          debtorIndex++;
          sortedCreditors[creditorIndex] = MapEntry(creditor.key, creditor.value - debtor.value);
        }
      } else {
        creditorIndex++;
        debtorIndex++;
      }
    }

    return debts;
  }

  /// Получает общую сумму всех транзакций
  static double getTotalAmount(List<Transaction> transactions) {
    return transactions.fold(0.0, (sum, transaction) => sum + transaction.totalAmount);
  }

  /// Получает количество активных участников (участвующих в транзакциях)
  static int getActiveParticipantsCount(List<Participant> participants, List<Transaction> transactions) {
    final activeIds = <String>{};

    for (final transaction in transactions) {
      activeIds.add(transaction.payerId);
      activeIds.addAll(transaction.participantAmounts.keys);
    }

    return activeIds.length;
  }
}

/// Класс для представления долга между двумя участниками
class Debt {
  final String fromId; // кто должен
  final String toId; // кому должен
  final double amount; // сумма долга

  const Debt({required this.fromId, required this.toId, required this.amount});

  @override
  String toString() {
    return 'Debt(from: $fromId, to: $toId, amount: $amount)';
  }
}
