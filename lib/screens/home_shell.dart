import 'package:flutter/material.dart';

import '../api/hospitals_api.dart';
import '../theme.dart';
import 'alerts_screen.dart';
import 'hospital_list_screen.dart';
import 'nurses_screen.dart';

/// Barre d'onglets du bas de la maquette : Hôpitaux, À domicile, Alertes.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api});

  final HospitalsApi api;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Chaque onglet garde sa position et ses données quand on passe de l'un à l'autre.
      body: IndexedStack(
        index: _tab,
        children: [
          HospitalListScreen(api: widget.api),
          const NursesScreen(),
          AlertsScreen(onFindHospital: () => setState(() => _tab = 0)),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: LafiaColors.divider))),
        child: NavigationBarTheme(
          // Style de la maquette : pastille bleu clair, libellé bleu en gras pour l'onglet actif.
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            indicatorColor: LafiaColors.blueSoft,
            height: 72,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
                color: states.contains(WidgetState.selected) ? LafiaColors.blueDark : LafiaColors.muted,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 22,
                color: states.contains(WidgetState.selected) ? LafiaColors.blueDark : LafiaColors.muted,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (index) => setState(() => _tab = index),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.local_hospital_outlined), label: 'Hôpitaux'),
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'À domicile'),
              NavigationDestination(icon: Icon(Icons.crisis_alert_outlined), label: 'Alertes'),
            ],
          ),
        ),
      ),
    );
  }
}
