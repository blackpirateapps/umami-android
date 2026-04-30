import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'application/providers/auth_controller.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/login_page.dart';

class UmamiAnalyticsApp extends ConsumerWidget {
  const UmamiAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider);

    return ShadApp(
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      themeMode: ThemeMode.system,
      home: session.when(
        data: (value) {
          if (value == null) {
            return const LoginPage();
          }
          return DashboardPage(session: value);
        },
        error: (error, stackTrace) => LoginPage(initialError: error),
        loading: () => const _SplashPage(),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            Text('Umami Analytics', style: theme.textTheme.h4),
          ],
        ),
      ),
    );
  }
}
