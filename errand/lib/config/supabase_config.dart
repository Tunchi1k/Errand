/// Shared Supabase configuration.
///
/// The anon key is safe to include in the client application. It can still be
/// overridden at build time with:
/// --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
const String supabaseUrl = 'https://rfqnervrhxzackrmuoec.supabase.co';
const String supabaseKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcW5lcnZyaHh6YWNrcm11b2VjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTAxODUyMzAsImV4cCI6MjA2NTc2MTIzMH0.NywMytTREK2onPcAY53tUDS0tvulCK0eeuRKXMXbNg',
);

const String supabaseVerificationsBucket = 'verifications';
const String supabaseUserProfileBucket = 'userprofile';
