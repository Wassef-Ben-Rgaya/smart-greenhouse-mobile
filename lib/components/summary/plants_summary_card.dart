import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PlantsSummaryCard extends StatelessWidget {
  final int totalPlants;
  final DateTime lastUpdate;

  const PlantsSummaryCard({
    super.key,
    required this.totalPlants,
    required this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Total: $totalPlants culture${totalPlants > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Dernière mise à jour: ${DateFormat('dd MMMM yyyy', 'fr_FR').format(lastUpdate)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
