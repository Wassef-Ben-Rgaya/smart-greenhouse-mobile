import 'package:flutter/material.dart';

class AppStyles {
  // Couleurs
  static const Color primaryColor = Color(0xFF1A781F);
  static const Color secondaryColor = Color(0xFF57B817);
  static const Color editIconColor = Color(0xFFFFEA06);
  static const Color deleteIconColor = Colors.red;
  static const Color statusColor = Color(0xFF3F9C4C);

  // Dégradés
  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFF1A781F), Color(0xFF57B817)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Textes
  static const TextStyle appBarTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle dataTableHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  static const TextStyle plantNameStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 18,
  );

  static const TextStyle scientificNameStyle = TextStyle(
    fontSize: 15,
    color: Color(0xFF676767),
    fontStyle: FontStyle.italic,
  );

  static const TextStyle regularTextStyle = TextStyle(fontSize: 18);

  static const TextStyle statusTextStyle = TextStyle(
    color: Color(0xFF1C7A28),
    fontSize: 18,
  );
}
