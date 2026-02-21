import 'package:prayer_times/core/base/base_presenter.dart';
import 'package:prayer_times/core/utility/utility.dart';
import 'package:prayer_times/domain/usecases/get_notifications_usecase.dart';
import 'package:prayer_times/presentation/notification/presenter/notification_ui_state.dart';

class NotificationPresenter extends BasePresenter<NotificationUiState> {
  final GetNotificationsUseCase _getNotificationsUseCase;

  NotificationPresenter(this._getNotificationsUseCase);
  final Obs<NotificationUiState> uiState = Obs(NotificationUiState.empty());
  NotificationUiState get currentUiState => uiState.value;

  @override
  Future<void> addUserMessage(String message) async {
    uiState.value = currentUiState.copyWith(userMessage: message);
    showMessage(message: message);
  }

  @override
  Future<void> toggleLoading({required bool loading}) async {
    uiState.value = currentUiState.copyWith(isLoading: loading);
  }

  Future<void> loadNotifications() async {
    await parseDataFromEitherWithUserMessage(
      task: () => _getNotificationsUseCase.execute(),
      onDataLoaded: (notifications) {
        final bool hasUnread = notifications.any(
          (notification) => !notification.isRead,
        );
        uiState.value = currentUiState.copyWith(
          notifications: notifications,
          hasUnread: hasUnread,
        );
      },
      showLoading: true,
    );
  }

  Future<void> markAsRead(String id) async {
    await parseDataFromEitherWithUserMessage(
      task: () => _getNotificationsUseCase.markAsRead(id),
      onDataLoaded: (data) {
        loadNotifications();
      },
      showLoading: true,
    );
  }

  Future<void> clearAll() async {
    await parseDataFromEitherWithUserMessage(
      task: () => _getNotificationsUseCase.clearAll(),
      onDataLoaded: (data) {
        loadNotifications();
      },
      showLoading: true,
    );
  }

  /// Selection mode toggle
  void toggleSelectionMode() {
    final bool newMode = !currentUiState.isSelectionMode;
    uiState.value = currentUiState.copyWith(
      isSelectionMode: newMode,
      selectedIds: newMode ? currentUiState.selectedIds : {},
    );
  }

  /// একটি notification select/deselect toggle
  void toggleSelection(String id) {
    final Set<String> updated = Set<String>.from(currentUiState.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    uiState.value = currentUiState.copyWith(selectedIds: updated);
  }

  /// সব notification select করা
  void selectAll() {
    final Set<String> allIds =
        currentUiState.notifications.map((n) => n.id).toSet();
    uiState.value = currentUiState.copyWith(selectedIds: allIds);
  }

  /// Selected notification গুলো delete করা
  Future<void> deleteSelected() async {
    final List<String> ids = currentUiState.selectedIds.toList();
    if (ids.isEmpty) return;

    await parseDataFromEitherWithUserMessage(
      task: () => _getNotificationsUseCase.deleteNotifications(ids),
      onDataLoaded: (data) {
        uiState.value = currentUiState.copyWith(
          isSelectionMode: false,
          selectedIds: {},
        );
        loadNotifications();
      },
      showLoading: true,
    );
  }

  @override
  void onInit() {
    loadNotifications();
    super.onInit();
  }
}
