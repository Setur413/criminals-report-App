import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://idpiuwtsrfoextbwzxmk.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkcGl1d3RzcmZvZXh0Ynd6eG1rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY1NDg0MTQsImV4cCI6MjA2MjEyNDQxNH0.DI58po6KXQtolxtnBjGXmLRlh5DqVLzQOzk3AQM_oHQ'
  ;
}

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
}