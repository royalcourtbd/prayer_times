import 'package:prayer_times/core/base/base_ui_state.dart';
import 'package:prayer_times/domain/entities/notification_entity.dart';

class NotificationUiState extends BaseUiState {
  final List<NotificationEntity> notifications;
  final bool hasUnread;
  final bool isSelectionMode;
  final Set<String> selectedIds;

  const NotificationUiState({
    required super.isLoading,
    required super.userMessage,
    required this.notifications,
    required this.hasUnread,
    this.isSelectionMode = false,
    this.selectedIds = const {},
  });

  factory NotificationUiState.empty() {
    return const NotificationUiState(
      isLoading: false,
      userMessage: '',
      notifications: [],
      hasUnread: false,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    userMessage,
    notifications,
    hasUnread,
    isSelectionMode,
    selectedIds,
  ];

  NotificationUiState copyWith({
    bool? isLoading,
    String? userMessage,
    List<NotificationEntity>? notifications,
    bool? hasUnread,
    bool? isSelectionMode,
    Set<String>? selectedIds,
  }) {
    return NotificationUiState(
      isLoading: isLoading ?? this.isLoading,
      userMessage: userMessage ?? this.userMessage,
      notifications: notifications ?? this.notifications,
      hasUnread: hasUnread ?? this.hasUnread,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}
