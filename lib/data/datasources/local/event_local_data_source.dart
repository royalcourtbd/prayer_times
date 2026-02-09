import 'dart:convert';

import 'package:prayer_times/data/models/event_model.dart';
import 'package:prayer_times/data/services/local_cache_service.dart';
import 'package:prayer_times/domain/entities/event_entity.dart';

abstract class EventLocalDataSource {
  Future<List<EventEntity>?> getCachedEvents();
  Future<void> cacheEvents(List<EventEntity> events);
  int? getCachedYear();
  Future<void> cacheYear(int year);
}

class EventLocalDataSourceImpl implements EventLocalDataSource {
  final LocalCacheService _localCacheService;

  EventLocalDataSourceImpl(this._localCacheService);

  @override
  Future<void> cacheEvents(List<EventEntity> events) async {
    final List<Map<String, dynamic>> jsonList = events
        .map((event) => EventModel.fromEntity(event).toJson())
        .toList();
    final String jsonString = jsonEncode(jsonList);
    await _localCacheService.saveData(key: CacheKeys.events, value: jsonString);
  }

  @override
  Future<List<EventEntity>?> getCachedEvents() async {
    final String? jsonString = _localCacheService.getData<String>(
      key: CacheKeys.events,
    );
    if (jsonString == null) return null;

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  int? getCachedYear() {
    return _localCacheService.getData<int>(key: CacheKeys.eventsYear);
  }

  @override
  Future<void> cacheYear(int year) async {
    await _localCacheService.saveData(key: CacheKeys.eventsYear, value: year);
  }
}
