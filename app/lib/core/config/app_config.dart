abstract final class AppConfig {
  static const appName = 'PG App';
  static const countryCode = '+91';
  static const termsUrl = '';
  static const privacyUrl = '';
  static const playStoreUrl = '';
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}

abstract final class AppFlags {
  static const remindersEnabled = false;
  static const uploadsEnabled = false;
  static const giveNoticeEnabled = false;
  static bool isPageApproved(String pageId) => false;
}

