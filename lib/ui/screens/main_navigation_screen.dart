import 'package:flutter/material.dart';

import '../../logic/member_controller.dart';
import '../layouts/main_navigation_layout.dart';

/// Pantalla raiz de la aplicacion.
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key, required this.controller});

  final MemberController controller;

  @override
  Widget build(BuildContext context) {
    return MainNavigationLayout(controller: controller);
  }
}
