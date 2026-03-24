import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout de l'import

class UserModel {
  final String? id;
  final String username;
  final String email;
  final String? role;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? birthDate;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? profileImageUrl; // URL de la photo de profil

  UserModel({
    this.id,
    required this.username,
    required this.email,
    this.role = 'utilisateur',
    this.firstName,
    this.lastName,
    this.gender,
    this.birthDate,
    this.phoneNumber,
    this.address,
    this.city,
    this.country = 'Tunisie',
    this.postalCode,
    this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String docId) {
    // Convertir un Timestamp ou un Map en DateTime
    DateTime? convertToDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is Map<String, dynamic>) {
        final seconds = value['_seconds'];
        final nanoseconds = value['_nanoseconds'];
        if (seconds is int && nanoseconds is int) {
          return DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds ~/ 1000000),
          );
        }
      }
      return null;
    }

    print(
      '🔥 Données Firestore reçues dans fromMap(): $data',
    ); // À remplacer par un logger en production
    return UserModel(
      id: docId,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      role: data['role'],
      firstName: data['firstName'],
      lastName: data['lastName'],
      gender: data['gender'],
      birthDate:
          data['birthDate'] is String
              ? data['birthDate']
              : convertToDateTime(data['birthDate'])?.toIso8601String(),
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      city: data['city'],
      country: data['country'],
      postalCode: data['postalCode'],
      createdAt: convertToDateTime(data['createdAt']),
      updatedAt: convertToDateTime(data['updatedAt']),
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'birthDate': birthDate,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? firstName,
    String? lastName,
    String? gender,
    String? birthDate,
    String? phoneNumber,
    String? address,
    String? city,
    String? country,
    String? postalCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
