import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ManaPriceApp extends StatelessWidget {
  const ManaPriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ManaPrice BR',
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
