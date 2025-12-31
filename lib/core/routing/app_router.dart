import 'package:flutter/material.dart';

import '../routing/auth_gate.dart';
import 'route_names.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/shell/screens/app_shell.dart';

class AppRouter {
  static const String initialRoute = RouteNames.authGate;

  static final Map<String, WidgetBuilder> routes = {
    RouteNames.authGate: (_) => const AuthGate(),
    RouteNames.login: (_) => const LoginScreen(),
    RouteNames.register: (_) => const RegisterScreen(),
    RouteNames.appShell: (_) => const AppShell(),
  };
}
