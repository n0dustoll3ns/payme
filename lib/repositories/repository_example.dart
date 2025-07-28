import '../domain/participant.dart';
import '../domain/transaction.dart';
import '../domain/trip.dart';
import 'local_repository_impl.dart';
import 'storage_keys.dart';

class RepositoryExample {
  final LocalRepositoryImpl _repository = LocalRepositoryImpl();

  // Пример работы с участниками
  Future<void> saveParticipant(Participant participant) async {
    await _repository.save(StorageKeys.participant, participant, (p) => p.toJson());
  }

  Future<Participant?> getParticipant() async {
    return await _repository.read(StorageKeys.participant, (json) => Participant.fromJson(json));
  }

  Future<void> saveParticipants(List<Participant> participants) async {
    await _repository.saveList(StorageKeys.participants, participants, (p) => p.toJson());
  }

  Future<List<Participant>> getParticipants() async {
    return await _repository.readList(StorageKeys.participants, (json) => Participant.fromJson(json));
  }

  // Пример работы с поездками
  Future<void> saveTrip(Trip trip) async {
    await _repository.save(StorageKeys.trip, trip, (t) => t.toJson());
  }

  Future<Trip?> getTrip() async {
    return await _repository.read(StorageKeys.trip, (json) => Trip.fromJson(json));
  }

  Future<void> saveTrips(List<Trip> trips) async {
    await _repository.saveList(StorageKeys.trips, trips, (t) => t.toJson());
  }

  Future<List<Trip>> getTrips() async {
    return await _repository.readList(StorageKeys.trips, (json) => Trip.fromJson(json));
  }

  // Пример работы с транзакциями
  Future<void> saveTransaction(Transaction transaction) async {
    await _repository.save(StorageKeys.transaction, transaction, (t) => t.toJson());
  }

  Future<Transaction?> getTransaction() async {
    return await _repository.read(StorageKeys.transaction, (json) => Transaction.fromJson(json));
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    await _repository.saveList(StorageKeys.transactions, transactions, (t) => t.toJson());
  }

  Future<List<Transaction>> getTransactions() async {
    return await _repository.readList(StorageKeys.transactions, (json) => Transaction.fromJson(json));
  }

  // Очистка данных
  Future<void> clearAllData() async {
    await _repository.clear(StorageKeys.participants);
    await _repository.clear(StorageKeys.trips);
    await _repository.clear(StorageKeys.transactions);
  }

  // Проверка существования данных
  Future<bool> hasParticipants() async {
    return await _repository.exists(StorageKeys.participants);
  }

  Future<bool> hasTrips() async {
    return await _repository.exists(StorageKeys.trips);
  }
}
