import 'package:flutter/material.dart';

/// Observer que imprime en consola cada vez que se navega a una pantalla,
/// para saber en qué archivo/página estás al depurar.
class RouteLoggingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final label = _routeLabel(route);
    debugPrint('[NAV] → $label');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final label = _routeLabel(route);
    debugPrint('[NAV] ← pop $label');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      debugPrint('[NAV] ⇄ replace → ${_routeLabel(newRoute)}');
    }
  }

  String _routeLabel(Route<dynamic> route) {
    // GoRouter pone en settings.name el nombre o path de la ruta
    return route.settings.name ?? route.runtimeType.toString();
  }
}
