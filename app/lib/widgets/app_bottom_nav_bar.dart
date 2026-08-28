import 'package:cricstatz/config/palette.dart';
import 'package:cricstatz/config/routes.dart';
import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppPalette.bgPrimary,
      selectedItemColor: AppPalette.navActive,
      unselectedItemColor: AppPalette.navInactive,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      elevation: 8,
      currentIndex: currentIndex,
      onTap: (int index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
          case 1:
            Navigator.pushNamed(context, AppRoutes.playerStats);
          case 2:
            Navigator.pushNamed(context, AppRoutes.teams);
          case 3:
            Navigator.pushNamed(context, AppRoutes.scoring);
          case 4:
            Navigator.pushNamed(context, AppRoutes.profile);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_outlined),
          activeIcon: Icon(Icons.bar_chart_rounded),
          label: 'Stats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group_outlined),
          activeIcon: Icon(Icons.group_rounded),
          label: 'Teams',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_cricket_outlined),
          activeIcon: Icon(Icons.sports_cricket_rounded),
          label: 'Scoring',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
