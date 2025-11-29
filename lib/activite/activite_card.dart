import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:yolo/activite/activite_model.dart';
import 'package:yolo/activite/categorie_data.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart';

class ActiviteCard extends StatelessWidget {
  final Activite activite;
  final VoidCallback? onTap;

  const ActiviteCard({
    super.key,
    required this.activite,
    this.onTap,
  });

  Future<Map<String, dynamic>?> _loadCreator() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(activite.createurId)
        .get();

    return snap.data();
  }

  @override
  Widget build(BuildContext context) {
    final cat = CategorieData.categories[activite.categorie];
    final Color catColor = cat?["color"] ?? Colors.deepPurple;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  StorageHelper.convert(activite.photoUrl),
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: catColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    activite.categorie,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 14,
                left: 14,
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _loadCreator(),
                  builder: (context, snap) {
                    final user = snap.data;

                    final String name =
                        user?["firstName"] ?? user?["username"] ?? "Créateur";
                    final String photo = user?["photoUrl"] ?? "";

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                              photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activite.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.05,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const Icon(Icons.place,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activite.adresse,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(Icons.event,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat("dd MMM yyyy à HH:mm", "fr_FR")
                              .format(activite.date),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.90),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        activite.estGratuite ? "Gratuit" : "Payant",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Positioned(
                bottom: 85,   // 🔥 remonté légèrement
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _computeDayLabel(activite.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _computeDayLabel(DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diffDays = dateOnly
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    if (diffDays == 0) return "Aujourd’hui";
    if (diffDays == 1) return "Demain";
    if (diffDays > 1 && diffDays <= 7) {
      return DateFormat("EEEE", "fr_FR").format(date);
    }
    return DateFormat("dd MMM", "fr_FR").format(date);
  }
}
