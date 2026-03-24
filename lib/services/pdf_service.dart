import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/kpi.dart'; // Adaptez selon le chemin réel

class PDFService {
  Future<File?> generateKPIHistoryPDF(
    List<KPI> history, {
    String? customPath,
  }) async {
    final pdf = pw.Document();

    // Charger les polices Roboto
    final robotoRegular = await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    );
    final robotoBold = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final robotoRegularFont = pw.Font.ttf(robotoRegular);
    final robotoBoldFont = pw.Font.ttf(robotoBold);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Text(
                'Historique des KPIs',
                style: pw.TextStyle(
                  fontSize: 24,
                  font: robotoBoldFont,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              ...history.map(
                (kpi) =>
                    _buildKpiSection(kpi, robotoRegularFont, robotoBoldFont),
              ),
            ],
      ),
    );

    // Si un chemin personnalisé est fourni, l'utiliser ; sinon, utiliser getApplicationDocumentsDirectory
    String filePath;
    if (customPath != null) {
      filePath = customPath;
    } else {
      final outputDir = await getApplicationDocumentsDirectory();
      filePath = "${outputDir.path}/historique_kpis.pdf";
    }

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Nouvelle méthode pour permettre à l'utilisateur de choisir un emplacement
  Future<String?> pickSaveLocation() async {
    try {
      // Demander les permissions de stockage (Android)
      if (Platform.isAndroid) {
        print('Demande de permissions de stockage...');
        final storageStatus = await Permission.storage.request();
        final manageStorageStatus =
            await Permission.manageExternalStorage.request();

        if (!storageStatus.isGranted || !manageStorageStatus.isGranted) {
          print('Permissions de stockage refusées.');
          return null;
        }
        print('Permissions de stockage accordées.');
      }

      // Utiliser file_picker pour permettre à l'utilisateur de choisir un répertoire
      print('Ouverture du sélecteur de répertoire...');
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory == null) {
        // L'utilisateur a annulé la sélection
        print('Sélection de l\'emplacement annulée par l\'utilisateur.');
        return null; // Permet de tomber sur le chemin par défaut
      }

      // Construire le chemin complet du fichier
      print('Répertoire sélectionné : $selectedDirectory');
      return "$selectedDirectory/historique_kpis.pdf";
    } catch (e) {
      print('Erreur lors de la sélection de l\'emplacement : $e');
      return null;
    }
  }

  pw.Widget _buildKpiSection(KPI kpi, pw.Font regularFont, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Date : ${kpi.date ?? 'Inconnue'}',
          style: pw.TextStyle(
            fontSize: 18,
            font: boldFont,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Bullet(
          text:
              'Température moyenne : ${kpi.avgTemperature.toStringAsFixed(1)} °C',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text: 'Humidité moyenne : ${kpi.avgHumidity.toStringAsFixed(1)} %',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text: 'Humidité du sol : ${kpi.soilHumidity.toStringAsFixed(1)} %',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Luminosité moyenne : ${kpi.avgLuminosity.toStringAsFixed(0)} lux',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Durée ensoleillement : ${kpi.sunlightDuration.toStringAsFixed(1)} h',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Durée ventilation : ${kpi.ventilationDuration.toStringAsFixed(1)} h',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text: 'Durée chauffage : ${kpi.heatingDuration.toStringAsFixed(1)} h',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Volume d\'eau total : ${kpi.totalWaterVolume.toStringAsFixed(2)} L',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Consommation énergétique : ${kpi.energyConsumption.toStringAsFixed(2)} kWh',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Intervalle moyen d\'arrosage : ${kpi.avgWateringInterval.toStringAsFixed(2)} h',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Efficacité lumineuse : ${kpi.lightEfficiency.toStringAsFixed(2)} %',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text: 'Interventions manuelles : ${kpi.manualInterventionCount}',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text: 'Durée pompe : ${kpi.pumpDuration.toStringAsFixed(1)} h',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text: 'Durée lampe : ${kpi.lampDuration.toStringAsFixed(1)} h',
          style: pw.TextStyle(font: regularFont),
        ),
        pw.Bullet(
          text:
              'Durée faible luminosité : ${kpi.lowLightDuration.toStringAsFixed(1)} h',
          style: pw.TextStyle(font: regularFont),
        ),
        if (kpi.dailyTotals != null) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            'Détails quotidiens :',
            style: pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold),
          ),
          pw.Bullet(
            text:
                'Pompe (jour) : ${(kpi.dailyTotals!.dailyPumpSeconds / 3600).toStringAsFixed(1)} h',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Bullet(
            text:
                'Ventilation (jour) : ${(kpi.dailyTotals!.dailyFanSeconds / 3600).toStringAsFixed(1)} h',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Bullet(
            text:
                'Chauffage (jour) : ${(kpi.dailyTotals!.dailyHeaterSeconds / 3600).toStringAsFixed(1)} h',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Bullet(
            text:
                'Lampe (jour) : ${(kpi.dailyTotals!.dailyLampSeconds / 3600).toStringAsFixed(1)} h',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Bullet(
            text:
                'Soleil (jour) : ${(kpi.dailyTotals!.dailySunlightSeconds / 3600).toStringAsFixed(1)} h',
            style: pw.TextStyle(font: regularFont),
          ),
          pw.Bullet(
            text:
                'Faible lumière (jour) : ${(kpi.dailyTotals!.dailyLowLightSeconds / 3600).toStringAsFixed(1)} h',
            style: pw.TextStyle(font: regularFont),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Divider(),
      ],
    );
  }
}
