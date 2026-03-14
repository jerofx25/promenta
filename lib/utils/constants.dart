import 'package:flutter/material.dart';

// Auth screen constants
class AuthConstants {
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;
}

// Onboarding constants
class OnboardingConstants {
  // Age selection constants
  static const int minAge = 16;
  static const int maxAge = 90;
  static const int defaultAge = 30;
  
  // Weight selection constants
  static const double minWeightKg = 40.0;
  static const double maxWeightKg = 180.0;
  static const double defaultWeightKg = 70.0;
  static const double minWeightLbs = 88.0; // 40kg in lbs
  static const double maxWeightLbs = 396.0; // 180kg in lbs
  static const double defaultWeightLbs = 154.0; // 70kg in lbs
  
  // Height selection constants
  static const double minHeightCm = 130.0;
  static const double maxHeightCm = 210.0;
  static const double defaultHeightCm = 170.0;
  static const double minHeightFt = 4.6; // 140cm in feet
  static const double maxHeightFt = 7.2; // 220cm in feet
  static const double defaultHeightFt = 5.6; // 170cm in feet
  
  // Training frequency options
  static const List<String> trainingFrequencies = [
    'Raramente',
    '1-2 veces por semana',
    '3-4 veces por semana',
    '5+ veces por semana',
    'Múltiples veces al día'
  ];
  
  // Fitness goals options
  static const List<String> fitnessGoals = [
    'Perder peso',
    'Ganar músculo',
    'Mejorar resistencia',
    'Mejorar flexibilidad',
    'Mantenimiento general'
  ];
  
  // Common injuries options
  static const List<String> commonInjuries = [
    'Dolor de espalda baja',
    'Lesión de rodilla',
    'Dolor de hombro',
    'Dolor de cuello',
    'Esguince de tobillo',
    'Tendinitis',
    'Codo de tenista',
    'Fascitis plantar',
    'Dolor de cadera',
    'Ninguna lesión'
  ];
  
  // Dietary habits options
  static const List<String> dietaryHabits = [
    'Omnívoro',
    'Vegetariano',
    'Vegano',
    'Cetogénico',
    'Paleo',
    'Sin gluten',
    'Sin lácteos',
    'Ayuno intermitente',
    'Bajo en carbohidratos',
    'Alto en proteínas'
  ];
}