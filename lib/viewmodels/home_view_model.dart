import 'package:flutter/foundation.dart';
import '../domain/participant.dart';
import '../repositories/local_repository_impl.dart';
import '../repositories/storage_keys.dart';

class HomeViewModel extends ChangeNotifier {
  final LocalRepositoryImpl _repository = LocalRepositoryImpl();

  List<Participant> _participants = [];
  bool _isLoading = false;
  String? _error;

  // Геттеры
  List<Participant> get participants => _participants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasParticipants => _participants.isNotEmpty;

  // Инициализация
  Future<void> initialize() async {
    await loadParticipants();
  }

  // Загрузка участников
  Future<void> loadParticipants() async {
    _setLoading(true);
    _clearError();

    try {
      final participants = await _repository.readList(StorageKeys.participants, (json) => Participant.fromJson(json));

      _participants = participants;
      notifyListeners();
    } catch (e) {
      _setError('Ошибка при загрузке участников: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Добавление участника
  Future<bool> addParticipant(String name) async {
    if (name.trim().isEmpty) {
      _setError('Имя участника не может быть пустым');
      return false;
    }

    if (name.trim().length < 2) {
      _setError('Имя должно содержать минимум 2 символа');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final participant = Participant(name: name.trim());

      _participants.add(participant);
      notifyListeners();

      await _repository.saveList(StorageKeys.participants, _participants, (p) => p.toJson());

      return true;
    } catch (e) {
      _setError('Ошибка при добавлении участника: $e');
      // Откатываем изменения в UI
      _participants.removeLast();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Удаление участника
  Future<bool> deleteParticipant(Participant participant) async {
    _setLoading(true);
    _clearError();

    try {
      final initialLength = _participants.length;
      _participants.removeWhere((p) => p.id == participant.id);

      if (_participants.length == initialLength) {
        _setError('Участник не найден');
        return false;
      }

      notifyListeners();

      await _repository.saveList(StorageKeys.participants, _participants, (p) => p.toJson());

      return true;
    } catch (e) {
      _setError('Ошибка при удалении участника: $e');
      // Пытаемся восстановить состояние
      await loadParticipants();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Очистка всех данных
  Future<void> clearAllData() async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.clear(StorageKeys.participants);
      _participants.clear();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка при очистке данных: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Проверка существования участника с таким именем
  bool hasParticipantWithName(String name) {
    return _participants.any((p) => p.name.toLowerCase() == name.trim().toLowerCase());
  }

  // Получение участника по ID
  Participant? getParticipantById(String id) {
    try {
      return _participants.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Приватные методы для управления состоянием
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
    notifyListeners();
  }

  // Очистка ошибки (для вызова из UI)
  void clearError() {
    _clearError();
  }
}
