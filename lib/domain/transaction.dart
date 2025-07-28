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
      id: json['id'] as String? ?? '',
      payerId: json['payerId'] as String? ?? '',
      totalAmount: _parseDouble(json['totalAmount']),
      participantAmounts: _parseParticipantAmounts(json['participantAmounts']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      description: json['description'] as String?,
    );
  }

  // Вспомогательный метод для парсинга double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Вспомогательный метод для парсинга Map<String, double>
  static Map<String, double> _parseParticipantAmounts(dynamic value) {
    if (value == null) return <String, double>{};
    if (value is! Map) return <String, double>{};

    final Map<String, double> result = <String, double>{};
    value.forEach((key, value) {
      if (key is String) {
        result[key] = _parseDouble(value);
      }
    });
    return result;
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
