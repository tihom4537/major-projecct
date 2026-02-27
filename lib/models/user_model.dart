import 'package:flutter/material.dart';
import 'spectral_data_model.dart';

class UserModel {
  final int? id;
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SpectralReading? latestReading;

  UserModel({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    this.email,
    this.phone,
    required this.createdAt,
    this.updatedAt,
    this.latestReading,
  });

  factory UserModel.fromDbMap(Map<String, dynamic> map, {SpectralReading? latestReading}) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }
    
    return UserModel(
      id: map['id'],
      name: map['name'] ?? 'Unknown',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'Unknown',
      bloodGroup: map['blood_group'] ?? 'Unknown',
      email: map['email'],
      phone: map['phone'],
      createdAt: parseTimestamp(map['created_at']),
      updatedAt: map['updated_at'] != null ? parseTimestamp(map['updated_at']) : null,
      latestReading: latestReading,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'blood_group': bloodGroup,
      'email': email,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Check if user has reading data
  bool get hasReadingData => latestReading != null;

  // Status based on signal quality (using NIR as indicator)
  String get signalStatus {
    if (latestReading == null) return 'No Data';
    final nir = latestReading!.channels.nir;
    if (nir > 500) return 'Strong';
    if (nir > 100) return 'Good';
    if (nir > 50) return 'Weak';
    return 'Very Weak';
  }

  Color get statusColor {
    if (latestReading == null) return const Color(0xFF9E9E9E);
    final nir = latestReading!.channels.nir;
    if (nir > 500) return const Color(0xFF4CAF50);
    if (nir > 100) return const Color(0xFF8BC34A);
    if (nir > 50) return const Color(0xFFFFC107);
    return const Color(0xFFF44336);
  }

  UserModel copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    String? bloodGroup,
    String? email,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    SpectralReading? latestReading,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latestReading: latestReading ?? this.latestReading,
    );
  }
}

class CreateUserRequest {
  final String name;
  final int age;
  final String gender;
  final String bloodGroup;
  final String? email;
  final String? phone;

  CreateUserRequest({
    required this.name,
    required this.age,
    required this.gender,
    required this.bloodGroup,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'blood_group': bloodGroup,
      'email': email,
      'phone': phone,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}