import 'package:flutter/material.dart';

class AppColors {
  // 🌄 Fond général du profil (dégradé doux et équilibré)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFFFFBEB), // beige clair
      Color(0xFFFFF5EE), // pêche très pâle
      Color(0xFFEFF6FF), // bleu lavande clair
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.45, 1.0],
  );

  // 🌅 Dégradé de la barre du haut (orange → corail naturel)
  static const LinearGradient headerGradient = LinearGradient(
    colors: [
      Color(0xFFFFB347), // orange doux
      Color(0xFFFF7E5F), // corail lumineux
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 1.0],
  );

  // 🌇 Dégradé de la barre du bas (plus doux)
  static const LinearGradient footerGradient = LinearGradient(
    colors: [
      Color(0xFFFFCC80), // abricot clair
      Color(0xFFFF8A65), // corail moyen
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 1.0],
  );

  // 🌈 Bouton principal (violet → orange)
  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      Color(0xFFA855F7), // violet
      Color(0xFFF97316), // orange
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
