import 'package:flutter/material.dart';
import 'activite_fiche_page.dart';

void openActiviteFicheModal(BuildContext context, String activiteId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.4),
    builder: (context) {
      return FractionallySizedBox(
        heightFactor: 0.96,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ActiviteFichePage(activiteId: activiteId),
        ),
      );
    },
  );
}
