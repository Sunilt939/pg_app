import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/notifications_repository.dart';

class SupabaseNotificationsRepository implements NotificationsRepository {
  final SupabaseClient? _client;

  SupabaseNotificationsRepository([SupabaseClient? client])
      : _client = client ??
            (Supabase.instance.isInitialized ? Supabase.instance.client : null);

  @override
  Future<List<NotificationItem>> getNotifications({int offset = 0, int limit = 50}) async {
    final client = _client;
    if (client == null) return const [];

    final response = await client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((row) => NotificationItem.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markAsRead(String id) async {
    final client = _client;
    if (client == null) return;

    await client.from('notifications').update({
      'status': 'read',
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<bool> hasUnreadNotifications() async {
    final client = _client;
    if (client == null) return false;

    final response = await client
        .from('notifications')
        .select('id')
        .neq('status', 'read')
        .isFilter('read_at', null)
        .limit(1);

    return (response as List<dynamic>).isNotEmpty;
  }
}
