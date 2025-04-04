// lib/router/router_notifier.dart
import 'package:flutter/material.dart';

class AppRouterNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final AppRouterNotifier routerNotifier = AppRouterNotifier();
