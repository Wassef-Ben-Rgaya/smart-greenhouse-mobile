import 'package:flutter/material.dart';
import 'package:serre_app/constants/styles.dart';
import 'package:serre_app/models/culture.dart';
import 'package:serre_app/services/plant_prediction_service.dart';
import 'package:serre_app/models/plant_prediction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';

// New professional color palette
const Color primaryColor = Color(0xFF1A781F); // Dark green
const Color secondaryColor = Color(0xFF388E3C); // Medium green
const Color accentColor = Color(0xFF8BC34A); // Light green
const Color backgroundColor = Color(0xFFF5F5F5); // Very light gray
const Color cardBackgroundColor = Colors.white;
const Color textColor = Color(0xFF212121); // Dark gray
const Color secondaryTextColor = Color(0xFF757575); // Medium gray
const Color errorColor = Color(0xFFD32F2F); // Red
const Color successColor = Color(0xFF1A781F); // Green
const Color warningColor = Color(0xFFFFA000); // Orange
const Color infoColor = Color(0xFF1976D2); // Blue

// Text styles
const TextStyle headerStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w800,
  color: textColor,
  letterSpacing: 0.5,
);

const TextStyle subheaderStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: secondaryTextColor,
);

const TextStyle cardTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: textColor,
);

const TextStyle cardSubtitleStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: secondaryTextColor,
);

const TextStyle bodyTextStyle = TextStyle(fontSize: 14, color: textColor);

const TextStyle captionTextStyle = TextStyle(
  fontSize: 12,
  color: secondaryTextColor,
);

class FullScreenImage extends StatefulWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  State<FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  double _manualRotationAngle = 0.0;
  double _deviceRotationAngle = 0.0;

  void _rotateLeft() {
    setState(() {
      _manualRotationAngle -= 90 * (3.1415926535 / 180);
    });
  }

  void _rotateRight() {
    setState(() {
      _manualRotationAngle += 90 * (3.1415926535 / 180);
    });
  }

  double _getDeviceRotationAngle(Orientation orientation) {
    if (orientation == Orientation.landscape) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      if (screenWidth > screenHeight) {
        return -90 * (3.1415926535 / 180);
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    _deviceRotationAngle = _getDeviceRotationAngle(orientation);
    final totalRotationAngle = _manualRotationAngle + _deviceRotationAngle;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_left, color: Colors.white, size: 28),
            onPressed: _rotateLeft,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white, size: 28),
            onPressed: _rotateRight,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Transform.rotate(
            angle: totalRotationAngle,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                    color: accentColor,
                    strokeWidth: 3,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white70,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Error',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AIPredictionScreen extends StatefulWidget {
  const AIPredictionScreen({super.key});

  @override
  AIPredictionScreenState createState() => AIPredictionScreenState();
}

class AIPredictionScreenState extends State<AIPredictionScreen> {
  final PlantPredictionService _predictionService = PlantPredictionService();
  late Future<Map<String, Map<String, dynamic>>> _groupedPredictionsFuture;
  final Map<String, Culture?> _culturesCache = {};
  final Map<String, Plant?> _plantsCache = {};
  late Future<Map<String, Map<String, Map<String, dynamic>>>>
  _predictionsByDateAndImageFuture;

  @override
  void initState() {
    super.initState();
    _groupedPredictionsFuture = _predictionService.getGroupedPredictions();
    _predictionsByDateAndImageFuture = _fetchPredictionsByDateAndImage();
  }

  Future<void> _refreshPredictions() async {
    setState(() {
      _groupedPredictionsFuture = _predictionService.getGroupedPredictions();
      _predictionsByDateAndImageFuture = _fetchPredictionsByDateAndImage();
      _culturesCache.clear();
      _plantsCache.clear();
    });
  }

  Future<Map<String, Map<String, Map<String, dynamic>>>>
  _fetchPredictionsByDateAndImage() async {
    try {
      final plantSnapshot =
          await FirebaseFirestore.instance.collection('plants').get();
      final plants =
          plantSnapshot.docs.map((doc) => Plant.fromFirestore(doc)).toList();
      for (var plant in plants) {
        _plantsCache[plant.id!] = plant;
      }

      final groupedPredictions = await _groupedPredictionsFuture;
      Map<String, Map<String, Map<String, dynamic>>> predictionsByDateAndImage =
          {};

      groupedPredictions.forEach((imageUrl, data) {
        if (data['detected_plants'] != null &&
            (data['detected_plants'] as List).isNotEmpty) {
          final timestamp = data['timestamp'] as Timestamp;
          final formattedDate = DateFormat(
            'MMMM dd, yyyy, HH:mm',
          ).format(timestamp.toDate());
          if (!predictionsByDateAndImage.containsKey(formattedDate)) {
            predictionsByDateAndImage[formattedDate] = {};
          }
          predictionsByDateAndImage[formattedDate]![imageUrl] = data;
        }
      });

      return predictionsByDateAndImage;
    } catch (e) {
      return {};
    }
  }

  Future<void> _launchNewAnalysis() async {
    if (!mounted) return;

    final result = await showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('New Analysis', style: headerStyle.copyWith(fontSize: 20)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: primaryColor),
                  title: Text('Choose from Gallery', style: bodyTextStyle),
                  onTap: () => Navigator.pop(context, 'gallery'),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: primaryColor),
                  title: Text('Take a Photo', style: bodyTextStyle),
                  onTap: () => Navigator.pop(context, 'camera'),
                ),
              ],
            ),
          ),
    );

    if (result == null) return;

    final picker = ImagePicker();
    final pickedFile =
        result == 'gallery'
            ? await picker.pickImage(source: ImageSource.gallery)
            : await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Analysis in Progress...',
                    style: subheaderStyle.copyWith(color: textColor),
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.43.114:5000/prediction_des_plantes/'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          pickedFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      Navigator.pop(context); // Close loading overlay

      if (!mounted) return;
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final result = jsonDecode(responseBody);
        if (result['result'] != null) {
          await _refreshPredictions();
          if (!mounted) return;
          _showSuccessSnackbar('Analysis completed successfully');
        } else {
          if (!mounted) return;
          _showErrorSnackbar('Error during analysis');
        }
      } else {
        if (!mounted) return;
        _showErrorSnackbar('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading overlay
      if (!mounted) return;
      _showErrorSnackbar('Error: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _deletePredictions(String imageUrl, Map<String, dynamic> data) async {
    final confirmed = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirm Deletion', style: cardTitleStyle),
            content: Text(
              'Do you really want to delete this analysis?',
              style: bodyTextStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: bodyTextStyle),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: bodyTextStyle.copyWith(color: errorColor),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    await _predictionService.deletePrediction(imageUrl);
    await _refreshPredictions();
    if (!mounted) return;
    _showSuccessSnackbar('Analysis deleted');
  }

  Future<Culture?> _fetchCulture(String planteId) async {
    if (_culturesCache.containsKey(planteId)) {
      return _culturesCache[planteId];
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('cultures')
              .where('plante', isEqualTo: planteId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final culture = Culture.fromFirestore(querySnapshot.docs.first);
        _culturesCache[planteId] = culture;
        return culture;
      }
    } catch (e) {
      debugPrint('Error fetching culture: $e');
    }
    _culturesCache[planteId] = null;
    return null;
  }

  String _translatePhaseName(String frenchName) {
    const translations = {
      'Germination': 'Germination',
      'Levée': 'Emergence',
      'Développement des feuilles': 'Leaf Development',
      'Croissance des tiges et racines': 'Stem and Root Growth',
      'Montaison': 'Tillering',
      'Formation de la tête': 'Head Formation',
      'Floraison': 'Flowering',
      'Pollinisation': 'Pollination',
      'Fructification': 'Fruiting',
      'Maturation': 'Maturation',
      'Récolte': 'Harvest',
      'Sénescence': 'Senescence',
      'Épuisé': 'Exhausted',
      'Inconnue': 'Unknown',
    };
    return translations[frenchName] ?? frenchName;
  }

  String _translatePlantName(String frenchName) {
    const translations = {
      'Laitue_Romaine': 'Romaine Lettuce',
      'Epinard': 'Spinach',
      'Radis': 'Radish',
    };
    return translations[frenchName] ?? frenchName;
  }

  String _calculateTheoreticalPhase(Culture culture, DateTime predictionDate) {
    final daysSincePlanting =
        predictionDate.difference(culture.datePlantation).inDays;
    int cumulativeDays = 0;

    for (var phase in culture.phases) {
      cumulativeDays += phase.duree;
      if (daysSincePlanting <= cumulativeDays) {
        return _translatePhaseName(phase.nom);
      }
    }
    return culture.phases.isNotEmpty
        ? _translatePhaseName(culture.phases.last.nom)
        : _translatePhaseName('Inconnue');
  }

  final Map<String, String> _predictionPhaseMapping = {
    'Developpement_des_feuilles': 'Leaf Development',
    'Formation_de_la_tete': 'Head Formation',
    'Germination': 'Germination',
    'Recolte': 'Harvest',
  };

  Widget _buildPhaseStatusIndicator(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'Matching':
        color = successColor;
        icon = Icons.check_circle;
        break;
      case 'Behind':
        color = warningColor;
        icon = Icons.warning;
        break;
      case 'Ahead':
        color = infoColor;
        icon = Icons.trending_up;
        break;
      default:
        color = secondaryTextColor;
        icon = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(String imageUrl, Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as Timestamp;
    final formattedDate = DateFormat(
      'MMMM dd, yyyy, HH:mm',
    ).format(timestamp.toDate());
    final predictionDate = timestamp.toDate();
    final detectedPlants = data['detected_plants'] as List<PlantPrediction>;

    final sortedPlants =
        detectedPlants.map((prediction) {
            final plant = _plantsCache[prediction.plantId];
            return (
              prediction: prediction,
              zone: plant?.zone ?? 'Unknown Zone',
            );
          }).toList()
          ..sort((a, b) => a.zone.compareTo(b.zone));

    Map<String, ({IconData icon, Color color})> plantIcons = {
      'Laitue_Romaine': (
        icon: Icons.local_florist,
        color: const Color.fromARGB(255, 255, 0, 0),
      ),
      'Epinard': (
        icon: Icons.grass,
        color: const Color.fromARGB(255, 24, 205, 27),
      ),
      'Radis': (
        icon: Icons.local_dining,
        color: const Color.fromARGB(255, 220, 57, 201),
      ),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackgroundColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(imageUrl: imageUrl),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: cardSubtitleStyle.copyWith(fontSize: 15),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 24),
                    color: const Color.fromARGB(255, 237, 6, 6),
                    onPressed: () => _deletePredictions(imageUrl, data),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: primaryColor,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color.fromARGB(255, 180, 177, 177),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.broken_image,
                                color: secondaryTextColor,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image Not Available',
                                style: captionTextStyle,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...sortedPlants.map((entry) {
                final prediction = entry.prediction;
                final zone = entry.zone;
                final iconData =
                    plantIcons[prediction.plantName] ??
                    (icon: Icons.image, color: secondaryTextColor);
                final uniquePredictedPhases =
                    prediction.predictedPhases.toSet().toList();

                return FutureBuilder<Culture?>(
                  future: _fetchCulture(prediction.plantId),
                  builder: (context, snapshot) {
                    String phaseComparison = 'No Crop Associated';
                    String theoreticalPhase = 'Unknown';
                    List<Widget> phaseDetails = [];

                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data != null) {
                      final culture = snapshot.data!;
                      theoreticalPhase = _calculateTheoreticalPhase(
                        culture,
                        predictionDate,
                      );

                      final mappedPredictedPhases =
                          uniquePredictedPhases
                              .map(
                                (phase) =>
                                    _predictionPhaseMapping[phase] ?? phase,
                              )
                              .toList();

                      final phaseOrder =
                          culture.phases
                              .map((p) => _translatePhaseName(p.nom))
                              .toList();
                      final theoreticalIndex = phaseOrder.indexOf(
                        theoreticalPhase,
                      );

                      phaseDetails =
                          mappedPredictedPhases.map((predictedPhase) {
                            final predictedIndex = phaseOrder.indexOf(
                              predictedPhase,
                            );
                            String status;
                            Color statusColor;

                            if (predictedIndex == -1) {
                              status = 'Not Recognized';
                              statusColor = secondaryTextColor;
                            } else if (predictedIndex == theoreticalIndex) {
                              status = 'Matching';
                              statusColor = successColor;
                            } else if (predictedIndex < theoreticalIndex) {
                              status = 'Behind';
                              statusColor = warningColor;
                            } else {
                              status = 'Ahead';
                              statusColor = infoColor;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      predictedPhase,
                                      style: bodyTextStyle.copyWith(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  _buildPhaseStatusIndicator(status),
                                ],
                              ),
                            );
                          }).toList();

                      phaseComparison = 'Theoretical Phase: $theoreticalPhase';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          217,
                          216,
                          216,
                        ).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: iconData.color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  iconData.icon,
                                  color: iconData.color,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _translatePlantName(prediction.plantName),
                                style: cardTitleStyle.copyWith(
                                  color: iconData.color,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  zone,
                                  style: captionTextStyle.copyWith(
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            phaseComparison,
                            style: bodyTextStyle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          if (phaseDetails.isNotEmpty) ...[
                            Text(
                              'Predicted Phases:',
                              style: bodyTextStyle.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            ...phaseDetails,
                          ],
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        toolbarHeight: 48,
        title: Text(
          '📊 Plant Predictions',
          style: AppStyles.appBarTitleStyle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppStyles.appBarGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: Colors.white,
            onPressed: _refreshPredictions,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        backgroundColor: cardBackgroundColor,
        onRefresh: _refreshPredictions,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FutureBuilder<Map<String, Map<String, Map<String, dynamic>>>>(
            future: _predictionsByDateAndImageFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 2,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Error',
                        style: headerStyle.copyWith(color: errorColor),
                      ),
                      const SizedBox(height: 8),
                      Text('Please try again', style: subheaderStyle),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _refreshPredictions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: bodyTextStyle.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/no_data.png',
                        height: 120,
                        color: secondaryTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No Analyses Available',
                        style: headerStyle.copyWith(
                          fontSize: 20,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by analyzing a photo of your plants',
                        style: subheaderStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _launchNewAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'New Analysis',
                          style: bodyTextStyle.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final dates =
                  snapshot.data!.keys.toList()..sort(
                    (a, b) => DateFormat('MMMM dd, yyyy, HH:mm')
                        .parse(b)
                        .compareTo(DateFormat('MMMM dd, yyyy, HH:mm').parse(a)),
                  );

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: dates.length,
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final predictionsByImage = snapshot.data![date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...predictionsByImage.entries.map((entry) {
                        final imageUrl = entry.key;
                        final data = entry.value;
                        return _buildPredictionCard(imageUrl, data);
                      }),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchNewAnalysis,
        backgroundColor: const Color.fromARGB(255, 0, 128, 255),
        elevation: 4,
        child: const Icon(Icons.upload, color: Colors.white, size: 28),
      ),
    );
  }
}
