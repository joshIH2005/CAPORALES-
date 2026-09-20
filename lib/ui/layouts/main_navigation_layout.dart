import 'package:flutter/material.dart';

import '../../core/constants/app_gradients.dart';
import '../../logic/member_controller.dart';
import '../screens/add_member_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/scanner_screen.dart';

/// Layout principal: barra de navegacion inferior (Material 3)
/// que alterna entre DashBoard, Escaner y Nuevo Integrante.
class MainNavigationLayout extends StatefulWidget {
  const MainNavigationLayout({super.key, required this.controller});

  final MemberController controller;

  @override
  State<MainNavigationLayout> createState() => _MainNavigationLayoutState();
}

class _MainNavigationLayoutState extends State<MainNavigationLayout> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(controller: widget.controller),
      ScannerScreen(controller: widget.controller),
      AddMemberScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Escaner',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_add_alt_1_outlined),
            selectedIcon: Icon(Icons.person_add_alt_1),
            label: 'Nuevo',
          ),
        ],
      ),
    );
  }
}
