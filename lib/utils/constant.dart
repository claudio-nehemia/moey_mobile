import 'package:flutter/material.dart';
import '../config/environment.dart';

class Constants {
  // API — read from .env
  static String get baseUrl => AppConfig.baseUrl;

  // Colors - Moey Living Interior Design Theme
  static const primaryColor = Color(0xFF2C3E50);
  static const secondaryColor = Color(0xFFE8DCC4);
  static const accentColor = Color(0xFFD4AF37);
  static const backgroundColor = Color(0xFFFAF8F5);
  static const cardColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF5F1EB);
  static const textDark = Color(0xFF2C3E50);
  static const textMedium = Color(0xFF5D6D7E);
  static const textLight = Color(0xFF95A5A6);

  // Category Colors
  static const surveyColor = Color(0xFF5B8DB8);
  static const designColor = Color(0xFF8E6BAD);
  static const estimasiColor = Color(0xFFD4915E);
  static const financeColor = Color(0xFF6BAD8E);
  static const kontrakColor = Color(0xFFB85B5B);
  static const konstruksiColor = Color(0xFF5B9EA6);
  static const gambarKerjaColor = Color(0xFF5B6B8D);
  static const approvalColor = Color(0xFF8EAD6B);
  static const pmColor = Color(0xFF7F8C8D);

  // Status Colors
  static const successColor = Color(0xFF5A8F6B);
  static const errorColor = Color(0xFFB85B5B);
  static const warningColor = Color(0xFFD4915E);
  static const infoColor = Color(0xFF5B8DB8);

  // PM/Marketing Response
  static const marketingColor = Color(0xFF6B4F8D);
}