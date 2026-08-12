import 'package:go_router/go_router.dart';

import '../../data/providers/demo_card_provider.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/pages/batch_lookup_page.dart';
import '../../presentation/pages/card_scanner_page.dart';
import '../../presentation/result/result_page.dart';
import '../../presentation/search/search_page.dart';
import '../../presentation/settings/settings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SearchPage(initialName: extra?['name'] as String?);
      },
    ),
    GoRoute(
      path: '/batch',
      builder: (context, state) => BatchLookupPage(
        findCard: (name) => DemoCardProvider.find(name),
      ),
    ),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => CardScannerPage(
        onCardNameDetected: (name) {
          context.go('/search', extra: {'name': name});
        },
      ),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const <String, dynamic>{};
        return ResultPage(filters: extra);
      },
    ),
  ],
);
