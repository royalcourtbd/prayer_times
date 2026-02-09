import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/config/prayer_time_app_screen.dart';
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

  final ScrollController holidayScrollController = ScrollController();
  bool _userScrolled = false;

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

    holidayScrollController.addListener(_onUserScroll);
  }

  @override
  void onClose() {
    holidayScrollController.removeListener(_onUserScroll);
    holidayScrollController.dispose();
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

  Map<String, List<EventEntity>> _groupEventsByMonth(List<EventEntity> events) {
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

  /// Current বা next upcoming holiday-তে scroll করা (screen-এর center-এ)
  void scrollToCurrentHoliday([
    BuildContext? context,
    bool forceScroll = false,
  ]) {
    try {
      if (_userScrolled && !forceScroll) return;

      final events = currentUiState.allEvents;
      if (events.isEmpty || !holidayScrollController.hasClients) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int activeIndex = events.indexWhere((event) {
        final eventDate = DateTime.parse(event.date);
        final eventDay = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
        );
        return !eventDay.isBefore(today);
      });

      // সব event past হলে শেষ item-এ scroll
      if (activeIndex == -1) activeIndex = events.length - 1;

      double screenWidth = holidayScrollController.position.viewportDimension;
      if (context != null) {
        screenWidth = MediaQuery.of(context).size.width;
      }

      final double itemWidth = 55.percentWidth;
      final double leftPadding = twentyPx;
      final double rightMargin = twelvePx;

      double activePosition =
          leftPadding + activeIndex * (itemWidth + rightMargin);
      double scrollTo = activePosition - (screenWidth / 2) + (itemWidth / 2);

      scrollTo = scrollTo.clamp(
        0.0,
        holidayScrollController.position.maxScrollExtent,
      );

      holidayScrollController.animateTo(
        scrollTo,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
      );
    } catch (e) {
      log('Error in scrollToCurrentHoliday: $e');
    }
  }

  void scrollToCurrentHolidayWithDelay([BuildContext? context]) {
    _userScrolled = false;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context != null && !context.mounted) return;
      scrollToCurrentHoliday(context);
    });
  }

  void _onUserScroll() {
    if (holidayScrollController.position.isScrollingNotifier.value) {
      _userScrolled = true;
    }
  }
}
