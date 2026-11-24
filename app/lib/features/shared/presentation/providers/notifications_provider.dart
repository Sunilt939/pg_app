import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/supabase_notifications_repository.dart';
import '../../domain/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return SupabaseNotificationsRepository();
});

class NotificationsState {
  final List<NotificationItem> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsRepository _repo;
  static const int pageSize = 50;

  NotificationsNotifier(this._repo) : super(const NotificationsState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.getNotifications(offset: 0, limit: pageSize);
      state = state.copyWith(
        items: items,
        isLoading: false,
        hasMore: items.length == pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextItems = await _repo.getNotifications(
        offset: state.items.length,
        limit: pageSize,
      );
      state = state.copyWith(
        items: [...state.items, ...nextItems],
        isLoadingMore: false,
        hasMore: nextItems.length == pageSize,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> markAsRead(String id) async {
    final updated = state.items.map((item) {
      if (item.id == id && item.isUnread) {
        return item.copyWith(
          status: 'read',
          readAt: DateTime.now().toUtc(),
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);

    try {
      await _repo.markAsRead(id);
    } catch (_) {
      // Ignored for optimistic update
    }
  }
}

final notificationsProvider =
    StateNotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return NotificationsNotifier(repo);
});

final hasUnreadNotificationsProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  return repo.hasUnreadNotifications();
});
