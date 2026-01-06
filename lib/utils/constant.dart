import 'package:flutter/material.dart';

class Constants {
  // Ganti dengan IP komputer Anda jika testing di device fisik
  // Cek IP: ipconfig (Windows) atau ifconfig (Mac/Linux)
  static const String baseUrl = 'http://192.168.30.146:8000/api'; // API Server
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  
  // Colors - Interior Design Theme
  static const primaryColor = Color(0xFF2C3E50);      // Dark Blue Gray
  static const secondaryColor = Color(0xFFE8DCC4);    // Warm Beige
  static const accentColor = Color(0xFFD4AF37);       // Gold
  static const backgroundColor = Color(0xFFF5F5F5);   // Light Gray
  static const textDark = Color(0xFF2C3E50);
  static const textLight = Color(0xFF7F8C8D);
}