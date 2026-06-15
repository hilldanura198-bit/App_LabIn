class SupabaseCredentials {
  const SupabaseCredentials._();

  static const url = 'https://yroretdotqcejhouwfqh.supabase.co';
  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlyb3JldGRvdHFjZWpob3V3ZnFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3NDMwMjgsImV4cCI6MjA5NjMxOTAyOH0.efPZ9l3aU7rla5N1VULcN58G1K3gJu5PgiodoWx7js0';

  static bool get isConfigured {
    return url.startsWith('https://') &&
        !url.contains('your-project-ref') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('your-supabase');
  }
}
