import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_repository_interface.dart';

class LocalRepositoryImpl implements LocalRepositoryInterface {
  @override
  Future<void> save<T>(String key, T model, Map<String, dynamic> Function(T) toJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(toJson(model));
    await prefs.setString(key, jsonString);
  }

  @override
  Future<void> saveList<T>(String key, List<T> models, Map<String, dynamic> Function(T) toJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonArray = models.map((model) => toJson(model)).toList();
    final jsonString = jsonEncode(jsonArray);
    await prefs.setString(key, jsonString);
  }

  @override
  Future<T?> read<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(jsonMap);
    } catch (e) {
      print('Ошибка при чтении данных для ключа $key: $e');
      return null;
    }
  }

  @override
  Future<List<T>> readList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonArray = jsonDecode(jsonString) as List<dynamic>;
      final models = <T>[];

      for (final jsonMap in jsonArray) {
        if (jsonMap is Map<String, dynamic>) {
          models.add(fromJson(jsonMap));
        }
      }

      return models;
    } catch (e) {
      print('Ошибка при чтении списка данных для ключа $key: $e');
      return [];
    }
  }

  @override
  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  @override
  Future<bool> exists(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key) && prefs.getString(key)?.isNotEmpty == true;
  }
}
