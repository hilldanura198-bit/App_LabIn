class SupabaseCredentials {
  const SupabaseCredentials._();

  static const url = 'https://your-project-ref.supabase.co';
  static const anonKey = 'your-supabase-anon-or-publishable-key';

  static bool get isConfigured {
    return url.startsWith('https://') &&
        !url.contains('your-project-ref') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('your-supabase');
  }
}
