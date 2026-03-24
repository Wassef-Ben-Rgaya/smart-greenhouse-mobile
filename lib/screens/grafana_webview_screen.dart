import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class GrafanaWebviewScreen extends StatefulWidget {
  const GrafanaWebviewScreen({super.key});

  @override
  State<GrafanaWebviewScreen> createState() => _GrafanaWebviewScreenState();
}

class _GrafanaWebviewScreenState extends State<GrafanaWebviewScreen> {
  late WebViewController _controller;
  final String grafanaUrl =
      'http://192.168.1.6:3000/d/bej0ytqoltwqob/serre?orgId=1&from=now-12h&to=now&timezone=browser';
  bool _isGrafanaAccessible = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _checkGrafanaUrl();
  }

  Future<void> _checkGrafanaUrl() async {
    try {
      final response = await http
          .get(Uri.parse(grafanaUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        setState(() {
          _isGrafanaAccessible = false;
        });
        await _loadNgrokUrlFromFirebase();
      }
    } catch (e) {
      print('Erreur lors de la vérification du lien Grafana : $e');
      setState(() {
        _isGrafanaAccessible = false;
      });
      await _loadNgrokUrlFromFirebase();
    }
  }

  Future<void> _loadNgrokUrlFromFirebase() async {
    try {
      final database = FirebaseDatabase.instance.ref();
      final snapshot = await database.child('ngrok_url').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        final ngrokUrl = data?['url'] as String?;
        if (ngrokUrl != null && ngrokUrl.isNotEmpty) {
          print('Chargement de l\'URL Ngrok depuis Firebase : $ngrokUrl');
          _controller.loadRequest(Uri.parse(ngrokUrl));
        } else {
          print('Aucune URL Ngrok valide trouvée dans Firebase');
        }
      } else {
        print('Nœud ngrok_url introuvable dans Firebase');
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'URL Ngrok : $e');
    }
  }

  void _initializeWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                print('Progression du chargement : $progress%');
              },
              onPageStarted: (String url) {
                print('Début du chargement de la page : $url');
              },
              onPageFinished: (String url) {
                print('Fin du chargement de la page : $url');
              },
              onWebResourceError: (WebResourceError error) {
                print(
                  'Erreur de chargement : ${error.description}, Code: ${error.errorCode}, Type: ${error.errorType}',
                );
                if (_isGrafanaAccessible) {
                  setState(() {
                    _isGrafanaAccessible = false;
                  });
                  _loadNgrokUrlFromFirebase();
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith(
                  'https://backend-serre-intelligente.onrender.com',
                )) {
                  print(
                    'Redirection vers HTTPS détectée, bloquée : ${request.url}',
                  );
                  return NavigationDecision.prevent;
                }
                print('Navigation vers : ${request.url}');
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(grafanaUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }

  void reloadGrafana() {
    _controller.reload();
  }
}
