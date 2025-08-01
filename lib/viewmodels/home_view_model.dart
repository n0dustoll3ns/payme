import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/participant.dart';
import '../domain/transaction.dart';
import '../domain/balance_calculator.dart';
import '../repositories/local_repository_impl.dart';
import '../repositories/storage_keys.dart';
import '../widgets/add_participant_bottom_sheet.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/balances_modal.dart';

class HomeViewModel extends ChangeNotifier {
  final LocalRepositoryImpl _repository = LocalRepositoryImpl();

  HomeViewModel() {
    init();
  }

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

  // Геттеры для балансов
  Map<String, double> get balances => BalanceCalculator.calculateBalances(_participants, _transactions);
  List<Debt> get debts => BalanceCalculator.calculateDebts(_participants, _transactions);
  double get totalAmount => BalanceCalculator.getTotalAmount(_transactions);
  int get activeParticipantsCount => BalanceCalculator.getActiveParticipantsCount(_participants, _transactions);
  bool get hasDebts => debts.isNotEmpty;

  init() async {
    _setLoading(true);

    await loadParticipants();
    await loadTransactions();
    _setLoading(false);
    notifyListeners();
  }

  // Методы для участников
  Future<void> loadParticipants() async {
    try {
      _participants = await _repository.readList<Participant>(StorageKeys.participants, (json) => Participant.fromJson(json));
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Ошибка загрузки участников: $e');
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
      notifyListeners();
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

  Future<void> updateTransaction(Transaction updatedTransaction) async {
    final index = _transactions.indexWhere((t) => t.id == updatedTransaction.id);
    if (index == -1) {
      _setError('Транзакция не найдена');
      return;
    }

    final oldTransaction = _transactions[index];
    _transactions[index] = updatedTransaction;

    try {
      await _repository.saveList(StorageKeys.transactions, _transactions, (t) => t.toJson());
      _clearError();
      notifyListeners();
    } catch (e) {
      _transactions[index] = oldTransaction;
      _setError('Ошибка обновления транзакции: $e');
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

  // Методы для работы с UI
  Future<void> showAddParticipantDialog(BuildContext context) async {
    // Проверяем, что нет транзакций
    if (transactions.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нельзя добавлять участников при наличии транзакций'), backgroundColor: Colors.orange));
      return;
    }

    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddParticipantBottomSheet(onSubmit: (name) => addParticipant(name)),
    );
  }

  Future<void> showAddTransactionDialog(BuildContext context, {Transaction? transaction}) async {
    // Проверяем, что есть минимум 2 участника
    if (participants.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Для добавления транзакции нужно минимум 2 участника'), backgroundColor: Colors.orange));
      return;
    }

    final result = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionBottomSheet(
        participants: participants,
        transaction: transaction, // передаем транзакцию для редактирования
      ),
    );

    if (result != null) {
      if (transaction != null) {
        // Обновляем существующую транзакцию
        await updateTransaction(result);
      } else {
        // Добавляем новую транзакцию
        await addTransaction(result);
      }
    }
  }

  Future<void> showDeleteParticipantDialog(BuildContext context, Participant participant) async {
    // Проверяем, участвует ли участник в транзакциях
    final isParticipantInTransactions = _transactions.any(
      (transaction) => transaction.payerId == participant.id || transaction.participantAmounts.containsKey(participant.id),
    );

    if (isParticipantInTransactions) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нельзя удалить участника, который участвует в транзакциях'), backgroundColor: Colors.orange));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить участника'),
        content: Text('Вы уверены, что хотите удалить "${participant.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteParticipant(participant);
      notifyListeners();
    }
  }

  Future<void> showDeleteTransactionDialog(BuildContext context, Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить транзакцию'),
        content: Text('Вы уверены, что хотите удалить транзакцию "${transaction.description ?? 'Без описания'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteTransaction(transaction);
      notifyListeners();
    }
  }

  Future<void> showBalancesModal(BuildContext context) async {
    // Проверяем, что есть участники и транзакции
    if (participants.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет участников для расчета балансов'), backgroundColor: Colors.orange));
      return;
    }

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Нет транзакций для расчета балансов'), backgroundColor: Colors.orange));
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider.value(value: this, child: const BalancesModal()),
    );
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
