import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class LunarStackApp extends StatelessWidget {
  const LunarStackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LunarStack',
      debugShowCheckedModeBanner: false,
      theme: buildLunarLightTheme(),
      darkTheme: buildLunarDarkTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
