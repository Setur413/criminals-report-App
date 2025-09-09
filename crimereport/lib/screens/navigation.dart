import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({required this.currentIndex, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) { // Prevent redundant navigation
          onTap(index);
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/student_dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/courses');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/history');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        }
      },
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed, // Ensures all items are visible
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
        BottomNavigationBarItem(icon: Icon(Icons.report_problem), label: "crime"),
        BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: "Track"),
      ],
    );
  }
}
