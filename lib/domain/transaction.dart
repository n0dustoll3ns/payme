class Transaction {
  final String id;
  final String payerId; // ID плательщика
  final double totalAmount; // общая сумма транзакции
  final Map<String, double> participantAmounts; // суммы по каждому участнику (ID -> сумма)
  final DateTime createdAt;
  final String? description; // описание транзакции

  Transaction({
    required this.id,
    required this.payerId,
    required this.totalAmount,
    required this.participantAmounts,
    DateTime? createdAt,
    this.description,
  }) : createdAt = createdAt ?? DateTime.now(),
       assert(_validateAmounts(totalAmount, participantAmounts));

  // Валидация: сумма всех участников должна равняться общей сумме
  static bool _validateAmounts(double totalAmount, Map<String, double> participantAmounts) {
    double sum = participantAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    return (sum - totalAmount).abs() < 0.01; // допускаем небольшую погрешность
  }

  // Создание копии с изменениями
  Transaction copyWith({
    String? id,
    String? payerId,
    double? totalAmount,
    Map<String, double>? participantAmounts,
    DateTime? createdAt,
    String? description,
  }) {
    return Transaction(
      id: id ?? this.id,
      payerId: payerId ?? this.payerId,
      totalAmount: totalAmount ?? this.totalAmount,
      participantAmounts: participantAmounts ?? this.participantAmounts,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
    );
  }

  // Конвертация в JSON для сохранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payerId': payerId,
      'totalAmount': totalAmount,
      'participantAmounts': participantAmounts,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }

  // Создание из JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      payerId: json['payerId'] ?? '',
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      participantAmounts: (json['participantAmounts'])?.map((k, v) => MapEntry(k, v.toDouble())) ?? <String, double>{},
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      description: json['description'] ?? '',
    );
  }

  // Получение суммы для конкретного участника
  double getAmountForParticipant(String participant) {
    return participantAmounts[participant] ?? 0.0;
  }

  // Проверка, участвует ли участник в транзакции
  bool isParticipantInvolved(String participant) {
    return participantAmounts.containsKey(participant) && participantAmounts[participant]! > 0;
  }
}
