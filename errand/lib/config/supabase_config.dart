const String supabaseUrl = 'https://rfqnervrhxzackrmuoec.supabase.co';
const String _defaultSupabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcW5lcnZyaHh6YWNrcm11b2VjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxODUyMzAsImV4cCI6MjA2NTc2MTIzMH0.NywMytTREK2onPcAY53tUDS0tvulCK0eeuRKXMXbNg';

final String supabaseKey = (() {
  final key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: _defaultSupabaseKey)
      .replaceAll(RegExp(r'\x1B\[[0-9;]*~'), '') // Remove ESC[...~ sequences
      .replaceAll(RegExp(r'^\[200~'), '') // Remove bracketed paste start
      .replaceAll(RegExp(r'~$'), '') // Remove trailing ~
      .trim();
  // Debug print to verify the key
  print('DEBUG: Supabase key length: ${key.length}');
  print('DEBUG: Supabase key starts with: ${key.substring(0, 20)}...');
  return key;
})();

const String supabaseVerificationsBucket = 'verifications';
const String supabaseUserProfileBucket = 'userprofile';
