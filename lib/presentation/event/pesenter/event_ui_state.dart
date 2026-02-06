import 'package:prayer_times/core/base/base_ui_state.dart';
import 'package:prayer_times/domain/entities/event_entity.dart';

class EventUiState extends BaseUiState {
  final String searchQuery;
  final Map<String, List<EventEntity>> groupedEvents;
  final List<EventEntity> allEvents;

  const EventUiState({
    required super.isLoading,
    required super.userMessage,
    required this.searchQuery,
    required this.groupedEvents,
    required this.allEvents,
  });

  factory EventUiState.empty() {
    return const EventUiState(
      isLoading: false,
      userMessage: '',
      searchQuery: '',
      groupedEvents: {},
      allEvents: [],
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    userMessage,
    searchQuery,
    groupedEvents,
    allEvents,
  ];

  EventUiState copyWith({
    bool? isLoading,
    String? userMessage,
    String? searchQuery,
    Map<String, List<EventEntity>>? groupedEvents,
    List<EventEntity>? allEvents,
  }) {
    return EventUiState(
      isLoading: isLoading ?? this.isLoading,
      userMessage: userMessage ?? this.userMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      groupedEvents: groupedEvents ?? this.groupedEvents,
      allEvents: allEvents ?? this.allEvents,
    );
  }
}
