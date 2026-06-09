// Basic smoke test. Most logic lives behind Supabase/auth, so this just
// verifies the app boots into the "not configured" state without crashing
// when no Supabase env vars are provided.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reef_tracker/app.dart';

void main() {
  testWidgets('App boots without Supabase config', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReefTrackerApp()));
    expect(find.text('Supabase is not configured'), findsOneWidget);
  });
}
