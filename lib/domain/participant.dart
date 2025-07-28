import 'dart:math';

class Participant {
  final String id;
  final String name;
  final DateTime createdAt;

  Participant({String? id, required this.name, DateTime? createdAt}) : id = id ?? _generateId(), createdAt = createdAt ?? DateTime.now();

  // Генерация уникального ID
  static String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  // Создание копии с изменениями
  Participant copyWith({String? id, String? name, DateTime? createdAt}) {
    return Participant(id: id ?? this.id, name: name ?? this.name, createdAt: createdAt ?? this.createdAt);
  }

  // Конвертация в JSON для сохранения
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'createdAt': createdAt.toIso8601String()};
  }

  // Создание из JSON
  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Participant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Participant(id: $id, name: $name)';
  }
}
