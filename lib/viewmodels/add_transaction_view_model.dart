import 'package:flutter/foundation.dart';
import '../domain/transaction.dart';

class AddTransactionViewModel extends ChangeNotifier {
  String? _selectedPayerId;
  double _totalAmount = 0.0;
  final Map<String, double> _participantAmounts = {};
  String? _description;
  String? _error;
  bool _isLoading = false;
  Transaction? _editingTransaction; // для отслеживания редактируемой транзакции

  // Геттеры
  String? get selectedPayerId => _selectedPayerId;
  double get totalAmount => _totalAmount;
  Map<String, double> get participantAmounts => Map.unmodifiable(_participantAmounts);
  String? get description => _description;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isEditing => _editingTransaction != null;

  // Вычисляемое свойство для отклонения суммы
  double get amountDeviation {
    double sum = _participantAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    return sum - _totalAmount;
  }

  // Инициализация для редактирования
  void initializeForEdit(Transaction? transaction) {
    if (transaction != null) {
      _editingTransaction = transaction;
      _selectedPayerId = transaction.payerId;
      _totalAmount = transaction.totalAmount;
      _description = transaction.description;
      _participantAmounts.clear();
      _participantAmounts.addAll(transaction.participantAmounts);
      notifyListeners();
    }
  }

  // Методы для изменения состояния
  void setPayer(String? payerId) {
    _selectedPayerId = payerId;
    _clearError();
    notifyListeners();
  }

  void setTotalAmount(double amount) {
    _totalAmount = amount;
    _clearError();
    notifyListeners();
  }

  void setParticipantAmount(String participantId, double amount) {
    if (amount > 0) {
      _participantAmounts[participantId] = amount;
    } else {
      _participantAmounts.remove(participantId);
    }
    _clearError();
    notifyListeners();
  }

  void setDescription(String? description) {
    _description = description;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Валидация формы
  bool validateForm() {
    // Проверяем, выбран ли плательщик
    if (_selectedPayerId == null || _selectedPayerId!.isEmpty) {
      setError('Выберите плательщика');
      return false;
    }

    // Проверяем, что общая сумма больше 0
    if (_totalAmount <= 0) {
      setError('Общая сумма должна быть больше 0');
      return false;
    }

    // Проверяем, что сумма участников равна общей сумме
    double sum = _participantAmounts.values.fold(0.0, (sum, amount) => sum + amount);
    if ((sum - _totalAmount).abs() > 0.01) {
      setError('Сумма участников (${sum.toStringAsFixed(2)} ₽) не равна общей сумме (${_totalAmount.toStringAsFixed(2)} ₽)');
      return false;
    }

    // Проверяем, что есть хотя бы один участник
    if (_participantAmounts.isEmpty) {
      setError('Добавьте хотя бы одного участника');
      return false;
    }

    return true;
  }

  // Создание или обновление транзакции
  Transaction? createTransaction() {
    if (!validateForm()) {
      return null;
    }

    if (isEditing && _editingTransaction != null) {
      // Обновляем существующую транзакцию
      return _editingTransaction!.copyWith(
        payerId: _selectedPayerId!,
        totalAmount: _totalAmount,
        participantAmounts: Map.from(_participantAmounts),
        description: _description?.trim().isEmpty == true ? null : _description?.trim(),
      );
    } else {
      // Создаем новую транзакцию
      return Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        payerId: _selectedPayerId!,
        totalAmount: _totalAmount,
        participantAmounts: Map.from(_participantAmounts),
        description: _description?.trim().isEmpty == true ? null : _description?.trim(),
      );
    }
  }

  // Сброс формы
  void reset() {
    _selectedPayerId = null;
    _totalAmount = 0.0;
    _participantAmounts.clear();
    _description = null;
    _error = null;
    _isLoading = false;
    _editingTransaction = null; // сбрасываем редактируемую транзакцию
    notifyListeners();
  }
}
