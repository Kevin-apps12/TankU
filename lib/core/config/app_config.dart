/// App configuration read from compile-time environment variables.
///
/// Pass these when running/building, e.g.:
///   flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=eyJ...
///
/// The Supabase anon key is safe to ship in the client (it is gated by
/// Row Level Security). Secrets like the Venice AI key live ONLY in the
/// Supabase Edge Function, never in this app.
class AppConfig {
  const AppConfig._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
