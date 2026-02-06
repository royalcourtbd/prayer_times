import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/domain/entities/event_entity.dart';
import 'package:prayer_times/domain/usecases/get_events_usecase.dart';
import 'package:prayer_times/presentation/event/pesenter/event_ui_state.dart';

class EventPresenter extends BasePresenter<EventUiState> {
  final GetEventsUseCase _getEventsUseCase;

  EventPresenter(this._getEventsUseCase);

  final Obs<EventUiState> uiState = Obs(EventUiState.empty());
  EventUiState get currentUiState => uiState.value;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadEvents();

    // TextEditingController এ লিসেনার যোগ করি যাতে ইনপুট পরিবর্তন হলেও সার্চ কাজ করে
    searchController.addListener(() {
      if (currentUiState.searchQuery != searchController.text) {
        updateSearchQuery(searchController.text);
      }
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadEvents({bool forceRefresh = false}) async {
    await parseDataFromEitherWithUserMessage<List<EventEntity>>(
      task: () => _getEventsUseCase.execute(forceRefresh: forceRefresh),
      showLoading: true,
      onDataLoaded: (List<EventEntity> events) {
        final sortedEvents = List<EventEntity>.from(events)
          ..sort((a, b) => a.date.compareTo(b.date));
        uiState.value = currentUiState.copyWith(allEvents: sortedEvents);
        processEvents();
      },
    );
  }

  // সার্চ কুয়েরি আপডেট মেথড
  void updateSearchQuery(String query) {
    if (currentUiState.searchQuery != query) {
      uiState.value = currentUiState.copyWith(searchQuery: query);
      processEvents();
    }
  }

  // ইভেন্ট প্রসেসিং এবং গ্রুপিং মেথড
  void processEvents() {
    final filteredAndSortedEvents = _processEvents(
      currentUiState.allEvents,
      currentUiState.searchQuery,
    );
    final groupedEvents = _groupEventsByMonth(filteredAndSortedEvents);
    uiState.value = currentUiState.copyWith(groupedEvents: groupedEvents);
  }

  // ইভেন্ট ফিল্টারিং মেথড
  List<EventEntity> _processEvents(List<EventEntity> events, String query) {
    var filteredEvents = events;
    if (query.isNotEmpty) {
      filteredEvents = events
          .where(
            (event) =>
                event.title.toLowerCase().contains(query.toLowerCase()) ||
                event.description.toLowerCase().contains(query.toLowerCase()) ||
                event.holidayType.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
    filteredEvents.sort((a, b) => a.date.compareTo(b.date));
    return filteredEvents;
  }

  Map<String, List<EventEntity>> _groupEventsByMonth(
    List<EventEntity> events,
  ) {
    final Map<String, List<EventEntity>> grouped = {};

    for (var event in events) {
      final date = DateTime.parse(event.date);
      final monthName = DateFormat('MMMM').format(date);

      if (!grouped.containsKey(monthName)) {
        grouped[monthName] = [];
      }
      grouped[monthName]!.add(event);
    }

    return grouped;
  }

  // কন্ট্রোলার ক্লিয়ার করার মেথড
  void clearSearchController() {
    searchController.clear();
    updateSearchQuery('');
  }

  @override
  Future<void> toggleLoading({bool loading = true}) async {
    uiState.value = currentUiState.copyWith(isLoading: loading);
  }

  @override
  Future<void> addUserMessage(String message) async {
    uiState.value = currentUiState.copyWith(userMessage: message);
    showMessage(message: currentUiState.userMessage);
  }
}
