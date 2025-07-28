import 'transaction.dart';
import 'participant.dart';

class Trip {
  final String id;
  final String name;
  final List<Participant> participants; // список участников
  final List<Transaction> transactions; // список транзакций
  final DateTime createdAt;

  Trip({required this.id, required this.name, required this.participants, required this.transactions, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  // Создание копии с изменениями
  Trip copyWith({String? id, String? name, List<Participant>? participants, List<Transaction>? transactions, DateTime? createdAt}) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      participants: participants ?? this.participants,
      transactions: transactions ?? this.transactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Конвертация в JSON для сохранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Создание из JSON
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'] ?? '',
      participants: (json['participants'] as List?)?.map((p) => Participant.fromJson(p)).toList() ?? <Participant>[],
      transactions: (json['transactions'] as List?)?.map((t) => Transaction.fromJson(t)).toList() ?? <Transaction>[],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  // Подсчёт общей суммы всех транзакций
  double get totalAmount {
    return transactions.fold(0.0, (sum, transaction) => sum + transaction.totalAmount);
  }

  // Подсчёт баланса для каждого участника
  Map<String, double> get participantBalances {
    Map<String, double> balances = {};

    // Инициализируем балансы всех участников
    for (Participant participant in participants) {
      balances[participant.id] = 0.0;
    }

    // Подсчитываем балансы
    for (Transaction transaction in transactions) {
      for (Participant participant in participants) {
        double amount = transaction.participantAmounts[participant.id] ?? 0.0;
        balances[participant.id] = balances[participant.id]! + amount;
      }
    }

    return balances;
  }
}
