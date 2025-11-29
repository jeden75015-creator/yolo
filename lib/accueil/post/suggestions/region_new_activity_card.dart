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

class NewActivityNearbyCard extends StatelessWidget {
  final Activite activite;

  const NewActivityNearbyCard({super.key, required this.activite});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: yoloBackgroundGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 70,
              height: 70,
              child: activite.photoUrl.isNotEmpty
                  ? Image.network(activite.photoUrl, fit: BoxFit.cover)
                  : Container(color: Colors.orange.withOpacity(0.4)),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Text(
              "Nouvelle activité près de chez vous : « ${activite.titre} »",
              style: const TextStyle(
                fontSize: 15, // <= 16
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

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
            child: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
