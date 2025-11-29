import 'package:flutter/material.dart';

import '../../../activite/activite_fiche_page.dart';
import '../../../activite/activite_model.dart';

const LinearGradient yoloBackgroundGradient = LinearGradient(
  colors: [
    Color(0xFFFFFBEB), // beige clair
    Color(0xFFFFF5EE), // pêche très pâle
    Color(0xFFEFF6FF), // bleu lavande clair
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class RecommendedActivityCard extends StatelessWidget {
  final Activite activite;

  const RecommendedActivityCard({super.key, required this.activite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: yoloBackgroundGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Recommandée pour vous 🌟",
            style: TextStyle(
              fontSize: 15, // <= 16
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ActiviteFichePage(activiteId: activite.id),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 160,
                child: activite.photoUrl.isNotEmpty
                    ? Image.network(activite.photoUrl, fit: BoxFit.cover)
                    : Container(color: Colors.orange.withOpacity(0.4)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            activite.titre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16, // max 16
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
