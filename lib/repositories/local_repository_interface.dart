abstract class LocalRepositoryInterface {
  /// Сохранение одной модели
  Future<void> save<T>(String key, T model, Map<String, dynamic> Function(T) toJson);

  /// Сохранение массива моделей
  Future<void> saveList<T>(String key, List<T> models, Map<String, dynamic> Function(T) toJson);

  /// Чтение одной модели
  Future<T?> read<T>(String key, T Function(Map<String, dynamic>) fromJson);

  /// Чтение массива моделей
  Future<List<T>> readList<T>(String key, T Function(Map<String, dynamic>) fromJson);

  /// Очистка данных по ключу
  Future<void> clear(String key);

  /// Проверка существования данных по ключу
  Future<bool> exists(String key);
}
