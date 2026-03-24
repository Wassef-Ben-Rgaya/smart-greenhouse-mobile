import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemTapped;
  final Color primaryColor;
  final VoidCallback? onMenuPressed;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
    required this.primaryColor,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.analytics,
              color: currentIndex == 0 ? primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => onItemTapped(0),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_remote,
              color: currentIndex == 2 ? primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => onItemTapped(2),
          ),
          const SizedBox(width: 40), // Espace pour le FAB
          IconButton(
            icon: Icon(
              Icons.auto_awesome,
              color: currentIndex == 3 ? primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => onItemTapped(3),
          ),
          IconButton(
            icon: Icon(
              Icons.show_chart,
              color: currentIndex == 1 ? primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => onItemTapped(1),
          ),
        ],
      ),
    );
  }
}

class CentralMenuButton extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onPressed;

  const CentralMenuButton({
    super.key,
    required this.primaryColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: primaryColor,
      elevation: 2,
      child: const Icon(Icons.menu, color: Colors.white),
    );
  }
}
