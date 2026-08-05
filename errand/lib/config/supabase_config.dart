/// Shared Supabase configuration.
///
/// Pass the anon key at build/run time with:
/// --dart-define=SUPABASE_ANON_KEY=<your-anon-key>
const String supabaseUrl = 'https://rfqnervrhxzackrmuoec.supabase.co';
const String supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

const String supabaseVerificationsBucket = 'verifications';
const String supabaseUserProfileBucket = 'userprofile';
