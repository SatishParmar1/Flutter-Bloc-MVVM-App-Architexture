import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/bloc/theme/theme_bloc.dart';
import 'core/bloc/theme/theme_state.dart';
import 'core/widgets/app_confetti_overlay.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;

    return BlocProvider<ThemeBloc>(
      create: (context) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: AppConfig.instance.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            routerConfig: router,
            debugShowCheckedModeBanner: !AppConfig.instance.isProd,
            builder: (context, child) {
              return AppConfettiOverlay(child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }
}
