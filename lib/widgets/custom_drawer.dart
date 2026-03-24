import 'package:flutter/material.dart';
import '../models/user.dart';
import '../constants/constants.dart';
import 'package:lottie/lottie.dart';

class CustomDrawer extends StatelessWidget {
  final UserModel user;

  const CustomDrawer({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryColor),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                Positioned(
                  top: 15,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 65,
                      height: 65,
                      child: Lottie.asset('assets/animations/plant.json'),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 15,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Smart Greenhouse',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFullNameOrUsername(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home_outlined,
                  title: 'Home',
                  route: '/home',
                ),
                // _buildDrawerItem(
                //  icon: Icons.dashboard_outlined,
                //  title: 'Dashboard',
                //  route: '/dashboard',
                // ),
                _buildDrawerItem(
                  icon: Icons.eco_outlined,
                  title: 'Plants',
                  route: '/plants',
                ),
                _buildDrawerItem(
                  icon: Icons.grass_outlined,
                  title: 'My Crops',
                  route: '/my-cultures',
                ),
                _buildDrawerItem(
                  icon: Icons.thermostat_outlined,
                  title: 'Environments',
                  route: '/environments',
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  title: 'Measurements',
                  route: '/measurements',
                ),
                _buildDrawerItem(
                  icon: Icons.notifications_outlined,
                  title: 'Alerts',
                  route: '/alerts',
                ),
                if (user.role == 'admin') ...[
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.manage_accounts_outlined,
                    title: 'User Management',
                    route: '/profile-management',
                  ),
                ],
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'My Profile',
                  route: '/settings',
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Log Out',
                  route: '/login',
                  replace: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFullNameOrUsername() {
    if ((user.firstName?.isNotEmpty ?? false) ||
        (user.lastName?.isNotEmpty ?? false)) {
      return '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    }
    return user.username;
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String route,
    bool replace = false,
  }) {
    return Builder(
      builder: (context) {
        return ListTile(
          leading: Icon(icon, color: kPrimaryColor, size: 24),
          title: Text(title, style: const TextStyle(fontSize: 18)),
          onTap: () {
            Navigator.pop(context);
            if (replace) {
              Navigator.pushReplacementNamed(context, route, arguments: user);
            } else {
              Navigator.pushNamed(context, route, arguments: user);
            }
          },
        );
      },
    );
  }
}
