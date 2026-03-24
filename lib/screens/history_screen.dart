import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../services/kpi_service.dart';
import '../services/pdf_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _savePDF(BuildContext context, KPIService kpiService) async {
    try {
      // Masquer le clavier avant toute action
      FocusScope.of(context).unfocus();

      final pdfService = PDFService();

      // Demander à l'utilisateur de choisir un emplacement
      final customPath = await pdfService.pickSaveLocation();

      if (customPath == null) {
        // Vérifier si l'annulation est due à des permissions refusées
        if (Platform.isAndroid) {
          final storageStatus = await Permission.storage.status;
          final manageStorageStatus =
              await Permission.manageExternalStorage.status;
          if (!storageStatus.isGranted || !manageStorageStatus.isGranted) {
            bool? retry = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Permissions refusées'),
                  content: const Text(
                    'L\'application a besoin d\'accès au stockage pour sauvegarder le PDF. Voulez-vous accorder les permissions ?',
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Non'),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    TextButton(
                      child: const Text('Oui'),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                );
              },
            );

            if (retry == true) {
              // Redemander les permissions et réessayer
              await [
                Permission.storage,
                Permission.manageExternalStorage,
              ].request();
              final newCustomPath = await pdfService.pickSaveLocation();
              if (newCustomPath != null) {
                final file = await pdfService.generateKPIHistoryPDF(
                  kpiService.kpiHistory,
                  customPath: newCustomPath,
                );
                if (file != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF enregistré : ${file.path}')),
                  );
                  await Share.shareXFiles(
                    [XFile(file.path, mimeType: 'application/pdf')],
                    text: 'Historique des KPIs',
                    subject: 'Exportation PDF - Historique des KPIs',
                  );
                  return;
                }
              }
            }
          }
        }

        // Si toujours null après tentative, proposer l'emplacement par défaut
        final defaultPath = await getApplicationDocumentsDirectory();
        final defaultFilePath = "${defaultPath.path}/historique_kpis.pdf";

        bool? useDefault = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sauvegarde annulée'),
              content: const Text(
                'Voulez-vous sauvegarder dans l\'emplacement par défaut ?',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Non'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Oui'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );

        if (useDefault == true) {
          final file = await pdfService.generateKPIHistoryPDF(
            kpiService.kpiHistory,
            customPath: defaultFilePath,
          );
          if (file != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF enregistré : ${file.path}')),
            );
            await Share.shareXFiles(
              [XFile(file.path, mimeType: 'application/pdf')],
              text: 'Historique des KPIs',
              subject: 'Exportation PDF - Historique des KPIs',
            );
            return;
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sauvegarde annulée')));
          return;
        }
      }

      // Générer le PDF avec le chemin choisi
      final file = await pdfService.generateKPIHistoryPDF(
        kpiService.kpiHistory,
        customPath: customPath,
      );

      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la génération du PDF')),
        );
        return;
      }

      // Afficher un message de confirmation
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF enregistré : ${file.path}')));

      // Partager le fichier PDF
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Historique des KPIs',
        subject: 'Exportation PDF - Historique des KPIs',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'exportation du PDF : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KPIService()..fetchKPIHistory(),
      child: Consumer<KPIService>(
        builder: (context, kpiService, child) {
          if (kpiService.isLoadingHistory) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Historique des KPIs'),
                backgroundColor: const Color(0xFF1A781F),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (kpiService.historyError != null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Historique des KPIs'),
                backgroundColor: const Color(0xFF1A781F),
              ),
              body: const Center(
                child: Text('Erreur lors du chargement de l\'historique'),
              ),
            );
          }

          final history = kpiService.kpiHistory;
          if (history.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Historique des KPIs'),
                backgroundColor: const Color(0xFF1A781F),
              ),
              body: const Center(child: Text('Aucun historique disponible')),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Historique des KPIs'),
              backgroundColor: const Color(0xFF1A781F),
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final kpi = history[index];
                final date = kpi.date;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      date ?? 'Date inconnue',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHistoryItem(
                              'Température moyenne',
                              '${kpi.avgTemperature.toStringAsFixed(1)} °C',
                            ),
                            _buildHistoryItem(
                              'Humidité moyenne',
                              '${kpi.avgHumidity.toStringAsFixed(1)} %',
                            ),
                            _buildHistoryItem(
                              'Luminosité moyenne',
                              '${kpi.avgLuminosity.toStringAsFixed(0)} lux',
                            ),
                            _buildHistoryItem(
                              'Humidité du sol',
                              '${kpi.soilHumidity.toStringAsFixed(1)} %',
                            ),
                            _buildHistoryItem(
                              'Volume d\'eau total',
                              '${kpi.totalWaterVolume.toStringAsFixed(2)} L',
                            ),
                            _buildHistoryItem(
                              'Consommation énergétique',
                              '${kpi.energyConsumption.toStringAsFixed(2)} kWh',
                            ),
                            _buildHistoryItem(
                              'Interventions manuelles',
                              '${kpi.manualInterventionCount}',
                            ),
                            _buildHistoryItem(
                              'Durée d\'éclairage',
                              '${kpi.lampDuration.toStringAsFixed(2)} h',
                            ),
                            _buildHistoryItem(
                              'Durée de ventilation',
                              '${kpi.ventilationDuration.toStringAsFixed(2)} h',
                            ),
                            _buildHistoryItem(
                              'Durée de chauffage',
                              '${kpi.heatingDuration.toStringAsFixed(2)} h',
                            ),
                            _buildHistoryItem(
                              'Durée d\'arrosage',
                              '${kpi.pumpDuration.toStringAsFixed(2)} h',
                            ),
                            _buildHistoryItem(
                              'Durée de faible luminosité',
                              '${kpi.lowLightDuration.toStringAsFixed(2)} h',
                            ),
                            _buildHistoryItem(
                              'Durée d\'ensoleillement',
                              '${kpi.sunlightDuration.toStringAsFixed(2)} h',
                            ),
                            _buildHistoryItem(
                              'Efficacité lumineuse',
                              kpi.lightEfficiency.toStringAsFixed(2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'history_pdf_button',
              onPressed: () => _savePDF(context, kpiService),
              tooltip: 'Exporter en PDF',
              child: const Icon(Icons.download),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
