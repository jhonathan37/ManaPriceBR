import 'package:go_router/go_router.dart';

import '../../data/local/quote_history_store.dart';
import '../../data/providers/card_price_provider.dart';
import '../../presentation/history/history_page.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/life/life_counter_page.dart';
import '../../presentation/pages/batch_lookup_page.dart';
import '../../presentation/pages/card_scanner_page.dart';
import '../../presentation/result/result_page.dart';
import '../../presentation/search/effect_search_page.dart';
import '../../presentation/search/search_page.dart';
import '../../presentation/settings/settings_page.dart';
import '../services/sale_session.dart';

final _cardPriceProvider = CardPriceProvider();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/life', builder: (context, state) => const LifeCounterPage()),
    GoRoute(path: '/history', builder: (context, state) => const HistoryPage()),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SearchPage(
          initialName: extra?['name'] as String?,
          initialCollectorNumber: extra?['collectorNumber'] as String?,
        );
      },
    ),
    GoRoute(path: '/effect-search', builder: (context, state) => const EffectSearchPage()),
    GoRoute(
      path: '/batch',
      builder: (context, state) => BatchLookupPage(findCard: (name) => _cardPriceProvider.find(name), onAddToSale: SaleSession.addAll),
    ),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => CardScannerPage(onCardDetected: (detected) { context.go('/search', extra: detected); }),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? const <String, dynamic>{};
        QuoteHistoryStore.add(extra);
        return ResultPage(filters: extra);
      },
    ),
  ],
);
