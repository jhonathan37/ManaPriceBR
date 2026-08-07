import 'package:go_router/go_router.dart';

import '../../presentation/batch/batch_page.dart';
import '../../presentation/home/home_page.dart';
import '../../presentation/search/search_page.dart';
import '../../presentation/settings/settings_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPage(),
    ),
    GoRoute(
      path: '/batch',
      builder: (context, state) => const BatchPage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
