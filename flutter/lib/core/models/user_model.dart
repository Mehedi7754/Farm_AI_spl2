import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { farmer, vet, admin }

class VetProfileModel {
  final String id;
  final String licenseNumber;
  final String specialization;
  final int experienceYears;
  final double consultationFee;
  final String availableFrom;
  final String availableTo;
  final List<String> availableDays;
  final String? bio;
  final String? profileImageUrl;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final String? district;

  const VetProfileModel({
    required this.id,
    required this.licenseNumber,
    required this.specialization,
    required this.experienceYears,
    required this.consultationFee,
    required this.availableFrom,
    required this.availableTo,
    required this.availableDays,
    this.bio,
    this.profileImageUrl,
    required this.rating,
    required this.totalReviews,
    required this.isVerified,
    required this.isAvailable,
    this.latitude,
    this.longitude,
    this.district,
  });

  factory VetProfileModel.fromJson(Map<String, dynamic> json) => VetProfileModel(
        id: json['id'] ?? '',
        licenseNumber: json['licenseNumber'] ?? '',
        specialization: json['specialization'] ?? '',
        experienceYears: json['experienceYears'] ?? 0,
        consultationFee: (json['consultationFee'] ?? 0).toDouble(),
        availableFrom: json['availableFrom'] ?? '09:00',
        availableTo: json['availableTo'] ?? '18:00',
        availableDays: List<String>.from(json['availableDays'] ?? []),
        bio: json['bio'],
        profileImageUrl: json['profileImageUrl'],
        rating: (json['rating'] ?? 0).toDouble(),
        totalReviews: json['totalReviews'] ?? 0,
        isVerified: json['isVerified'] ?? false,
        isAvailable: json['isAvailable'] ?? true,
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        district: json['district'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'licenseNumber': licenseNumber,
        'specialization': specialization,
        'experienceYears': experienceYears,
        'consultationFee': consultationFee,
        'availableFrom': availableFrom,
        'availableTo': availableTo,
        'availableDays': availableDays,
        'bio': bio,
        'profileImageUrl': profileImageUrl,
        'rating': rating,
        'totalReviews': totalReviews,
        'isVerified': isVerified,
        'isAvailable': isAvailable,
        'latitude': latitude,
        'longitude': longitude,
        'district': district,
      };
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final UserRole role;
  final String? location;
  final String? profileImageUrl;
  final String? fcmToken;
  final VetProfileModel? vetProfile;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.role,
    this.location,
    this.profileImageUrl,
    this.fcmToken,
    this.vetProfile,
  });

  bool get isVet => role == UserRole.vet;
  bool get isFarmer => role == UserRole.farmer;
  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] ?? 'FARMER').toString().toUpperCase();
    UserRole role;
    switch (roleStr) {
      case 'VET':
        role = UserRole.vet;
        break;
      case 'ADMIN':
        role = UserRole.admin;
        break;
      default:
        role = UserRole.farmer;
    }

    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      role: role,
      location: json['location'],
      profileImageUrl: json['profileImageUrl'],
      fcmToken: json['fcmToken'],
      vetProfile: json['vetProfile'] != null ? VetProfileModel.fromJson(json['vetProfile']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role.name.toUpperCase(),
        'location': location,
        'profileImageUrl': profileImageUrl,
        'fcmToken': fcmToken,
        'vetProfile': vetProfile?.toJson(),
      };
}

class AuthStorage {
  static const _userKey = 'current_user';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_userKey);
    if (str == null) return null;
    return UserModel.fromJson(jsonDecode(str));
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
