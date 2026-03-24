import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:serre_app/models/user.dart';
import 'package:serre_app/widgets/custom_drawer.dart';
import 'package:serre_app/screens/ai_prediction_screen.dart';
import 'package:serre_app/screens/analytics_dashboard_screen.dart';
import 'package:serre_app/screens/manual_control_screen.dart';
import 'package:serre_app/screens/history_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:serre_app/services/kpi_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class HomeWrapper extends StatefulWidget {
  final UserModel user;

  const HomeWrapper({super.key, required this.user});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _selectedIndex = 0;
  final Color _primaryColor = const Color(0xFF1A781F);
  late WebViewController _grafanaController;
  final KPIService _kpiService = KPIService();
  final String grafanaUrl =
      'http://192.168.1.6:3000/d/bej0ytqoltwqob/serre?orgId=1&from=now-12h&to=now&timezone=browser';
  bool _isLoading = true;
  String? _errorMessage;

  // Define the correct Firebase database URL
  final DatabaseReference _database =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://serre-intelligente-bac7c-default-rtdb.europe-west1.firebasedatabase.app',
      ).ref();

  final List<Widget> _pages = [
    Container(), // Initialized in initState
    const ManualControlScreen(),
    const AIPredictionScreen(),
    Container(), // Initialized in initState
  ];

  final List<String> _pageTitles = [
    'Dashboard',
    'Manual Control',
    'AI Prediction',
    'Grafana Dashboard',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializePages();
    _loadInitialData();
    _checkGrafanaUrl();
  }

  Future<void> _checkGrafanaUrl() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await http
          .get(Uri.parse(grafanaUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        print('Grafana not accessible, HTTP status: ${response.statusCode}');
        await _loadNgrokUrl();
      }
    } catch (e) {
      print('Error checking Grafana URL: $e');
      await _loadNgrokUrl();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNgrokUrl() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final snapshot = await _database.child('ngrok_url').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        final ngrokBaseUrl = data?['url'] as String?;
        if (ngrokBaseUrl != null && ngrokBaseUrl.isNotEmpty) {
          // Validate Ngrok URL
          final ngrokUri = Uri.tryParse(ngrokBaseUrl);
          if (ngrokUri != null &&
              (ngrokUri.scheme == 'http' || ngrokUri.scheme == 'https')) {
            // Extract path and query from Grafana URL
            final grafanaUri = Uri.parse(grafanaUrl);
            final pathAndQuery =
                '${grafanaUri.path}${grafanaUri.query.isNotEmpty ? '?${grafanaUri.query}' : ''}';
            // Construct full Ngrok URL
            final ngrokUrl = '$ngrokBaseUrl$pathAndQuery';
            print('Loading Ngrok URL from Firebase: $ngrokUrl');
            final ngrokFullUri = Uri.tryParse(ngrokUrl);
            if (ngrokFullUri != null) {
              _grafanaController.loadRequest(ngrokFullUri);
            } else {
              print('Invalid full Ngrok URL: $ngrokUrl');
              setState(() {
                _errorMessage = 'Invalid full Ngrok URL';
              });
            }
          } else {
            print('Invalid base Ngrok URL: $ngrokBaseUrl');
            setState(() {
              _errorMessage = 'Invalid base Ngrok URL in Firebase';
            });
          }
        } else {
          print('No valid Ngrok URL found in Firebase');
          setState(() {
            _errorMessage = 'No valid Ngrok URL found';
          });
        }
      } else {
        print('ngrok_url node not found in Firebase');
        setState(() {
          _errorMessage = 'ngrok_url node not found in Firebase';
        });
      }
    } catch (e) {
      print('Error retrieving Ngrok URL: $e');
      setState(() {
        _errorMessage = 'Error retrieving Ngrok URL: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeControllers() {
    _grafanaController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                print('Loading progress: $progress%');
                setState(() {
                  _isLoading = progress < 100;
                });
              },
              onPageStarted: (String url) {
                print('Page loading started: $url');
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
              },
              onPageFinished: (String url) {
                print('Page loading finished: $url');
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (WebResourceError error) {
                print(
                  'Loading error: ${error.description}, Code: ${error.errorCode}, Type: ${error.errorType}',
                );
                setState(() {
                  _errorMessage = 'Loading error: ${error.description}';
                });
                _loadNgrokUrl();
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith(
                  'https://backend-serre-intelligente.onrender.com',
                )) {
                  print('HTTPS redirection detected, blocked: ${request.url}');
                  return NavigationDecision.prevent;
                }
                print('Navigating to: ${request.url}');
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(grafanaUrl));
  }

  void _initializePages() {
    _pages[0] = ChangeNotifierProvider.value(
      value: _kpiService,
      child: const AnalyticsDashboardScreen(),
    );
    _pages[3] = Stack(
      children: [
        WebViewWidget(controller: _grafanaController),
        if (_isLoading)
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                      _grafanaController.loadRequest(Uri.parse(grafanaUrl));
                      _checkGrafanaUrl();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _loadInitialData() async {
    await _kpiService.fetchKPIs();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        backgroundColor: _primaryColor,
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _navigateToHistory,
              tooltip: 'History',
            ),
          ],
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _grafanaController.loadRequest(Uri.parse(grafanaUrl));
                _checkGrafanaUrl();
              },
              tooltip: 'Refresh',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: CustomDrawer(user: widget.user),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: _buildCentralMenuButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavBar() {
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
              color: _selectedIndex == 0 ? _primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => _onItemTapped(0),
            tooltip: 'Dashboard',
          ),
          IconButton(
            icon: Icon(
              Icons.settings_remote,
              color: _selectedIndex == 1 ? _primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => _onItemTapped(1),
            tooltip: 'Manual Control',
          ),
          const SizedBox(width: 40),
          IconButton(
            icon: Icon(
              Icons.auto_graph_sharp,
              color: _selectedIndex == 2 ? _primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => _onItemTapped(2),
            tooltip: 'Prediction',
          ),
          IconButton(
            icon: Icon(
              Icons.dashboard,
              color: _selectedIndex == 3 ? _primaryColor : Colors.grey,
              size: 30,
            ),
            onPressed: () => _onItemTapped(3),
            tooltip: 'Grafana Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildCentralMenuButton() {
    return FloatingActionButton(
      onPressed: () => _showMenuDialog(context),
      backgroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _primaryColor),
        child: const Icon(Icons.menu, color: Colors.white, size: 28),
      ),
    );
  }

  void _showMenuDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuOption(
                      icon: Icons.eco_outlined,
                      label: 'Plants',
                      onTap: () => _navigateTo('/plants'),
                    ),
                    _buildMenuOption(
                      icon: Icons.grass_outlined,
                      label: 'My Crops',
                      onTap: () => _navigateTo('/my-cultures'),
                    ),
                    _buildMenuOption(
                      icon: Icons.thermostat_outlined,
                      label: 'Environments',
                      onTap: () => _navigateTo('/environments'),
                    ),
                    _buildMenuOption(
                      icon: Icons.analytics_outlined,
                      label: 'Measurements',
                      onTap: () => _navigateTo('/measurements'),
                    ),
                    _buildMenuOption(
                      icon: Icons.notifications_outlined,
                      label: 'Alerts',
                      onTap: () => _navigateTo('/alerts'),
                    ),
                    if (widget.user.role == 'admin') ...[
                      const Divider(),
                      _buildMenuOption(
                        icon: Icons.manage_accounts_outlined,
                        label: 'User Management',
                        onTap: () => _navigateTo('/profile-management'),
                      ),
                    ],
                    const Divider(),
                    _buildMenuOption(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => _navigateTo('/settings'),
                    ),
                    _buildMenuOption(
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: _signOut,
                      textColor: Colors.red,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? _primaryColor, size: 28),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateTo(String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route, arguments: widget.user);
  }
}
