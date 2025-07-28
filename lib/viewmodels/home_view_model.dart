import 'package:flutter/foundation.dart';
import '../domain/participant.dart';
import '../domain/transaction.dart';
import '../repositories/local_repository_impl.dart';
import '../repositories/storage_keys.dart';

class HomeViewModel extends ChangeNotifier {
  final LocalRepositoryImpl _repository = LocalRepositoryImpl();

  List<Participant> _participants = [];
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Геттеры для участников
  List<Participant> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Геттеры для транзакций
  List<Transaction> get transactions => _transactions;
  bool get hasParticipants => _participants.isNotEmpty;

  // Методы для участников
  Future<void> loadParticipants() async {
    _setLoading(true);
    try {
      _participants = await _repository.readList<Participant>(StorageKeys.participants, (json) => Participant.fromJson(json));
      _clearError();
    } catch (e) {
      _setError('Ошибка загрузки участников: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addParticipant(String name) async {
    if (name.trim().isEmpty) {
      _setError('Имя участника не может быть пустым');
      return;
    }

    if (hasParticipantWithName(name.trim())) {
      _setError('Участник с таким именем уже существует');
      return;
    }

    final participant = Participant(name: name.trim());
    _participants.add(participant);

    try {
      await _repository.saveList(StorageKeys.participants, _participants, (participant) => participant.toJson());
      _clearError();
      notifyListeners();
    } catch (e) {
      _participants.remove(participant);
      _setError('Ошибка сохранения участника: $e');
      notifyListeners();
    }
  }

  Future<void> deleteParticipant(Participant participant) async {
    _participants.remove(participant);

    try {
      await _repository.saveList(StorageKeys.participants, _participants, (p) => p.toJson());
      _clearError();
      notifyListeners();
    } catch (e) {
      _participants.add(participant);
      _setError('Ошибка удаления участника: $e');
      notifyListeners();
    }
  }

  // Методы для транзакций
  Future<void> loadTransactions() async {
    try {
      _transactions = await _repository.readList<Transaction>(StorageKeys.transactions, (json) => Transaction.fromJson(json));
      _clearError();
    } catch (e) {
      _setError('Ошибка загрузки транзакций: $e');
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);

    try {
      await _repository.saveList(StorageKeys.transactions, _transactions, (t) => t.toJson());
      _clearError();
      notifyListeners();
    } catch (e) {
      _transactions.remove(transaction);
      _setError('Ошибка сохранения транзакции: $e');
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    _transactions.remove(transaction);

    try {
      await _repository.saveList(StorageKeys.transactions, _transactions, (t) => t.toJson());
      _clearError();
      notifyListeners();
    } catch (e) {
      _transactions.add(transaction);
      _setError('Ошибка удаления транзакции: $e');
      notifyListeners();
    }
  }

  // Вспомогательные методы
  bool hasParticipantWithName(String name) {
    return _participants.any((p) => p.name.toLowerCase() == name.toLowerCase());
  }

  Participant? getParticipantById(String id) {
    try {
      return _participants.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Participant? getPayerById(String payerId) {
    return getParticipantById(payerId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearAllData() async {
    try {
      await _repository.clear(StorageKeys.participants);
      await _repository.clear(StorageKeys.transactions);
      _participants.clear();
      _transactions.clear();
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка очистки данных: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
