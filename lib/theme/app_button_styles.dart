// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'app_dimensions.dart';

class AppButtonStyles {
  // 🌈 Bouton principal (violet → orange)
  static const LinearGradient mainGradient = LinearGradient(
    colors: [Color(0xFFA855F7), Color(0xFFF97316)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxDecoration mainButtonDecoration = BoxDecoration(
    gradient: mainGradient,
    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.15),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static const TextStyle mainButtonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // 🖤 Bouton secondaire — fond noir transparent, texte et contour orange
  static BoxDecoration secondaryButtonDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.4), // fond sombre transparent
    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
    border: Border.all(
      color: const Color(0xFFF97316), // orange du thème
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.orange.withOpacity(0.15),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static const TextStyle secondaryButtonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFFF97316), // texte orange
  );

  // 🟦 Bouton rond bleu — pour icônes (retour, etc.)
  static BoxDecoration blueCircleButtonDecoration = const BoxDecoration(
    shape: BoxShape.circle,
    color: Color(0xFF3B82F6),
  );

  static const TextStyle blueCircleButtonText = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );

  // 🔴 Bouton danger — pour supprimer, déconnecter, etc.
  static BoxDecoration dangerButtonDecoration = BoxDecoration(
    color: const Color(0xFFE53935), // rouge vif
    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
    border: Border.all(
      color: const Color(0xFFB71C1C), // rouge foncé
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.red.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static const TextStyle dangerButtonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // ⚪ Variante désactivée (non cliquable)
  static BoxDecoration disabledButtonDecoration = BoxDecoration(
    color: Colors.grey.withOpacity(0.3),
    borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
  );

  static const TextStyle disabledButtonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white54,
  );
}
