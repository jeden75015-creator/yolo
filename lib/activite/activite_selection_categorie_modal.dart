// -----------------------------------------------------------------------------
// 📄 MODAL : ActiviteSelectionCategorieModal (VERSION SIMPLE & PASTEL)
// Liste simple : emoji + nom catégorie + exemples
// Fond dégradé pastel YOLO
// -----------------------------------------------------------------------------  

import 'package:flutter/material.dart';
import 'categorie_data.dart';
import 'activite_creation_page.dart';

class ActiviteSelectionCategorieModal extends StatefulWidget {
  const ActiviteSelectionCategorieModal({super.key});

  @override
  State<ActiviteSelectionCategorieModal> createState() =>
      _ActiviteSelectionCategorieModalState();
}

class _ActiviteSelectionCategorieModalState
    extends State<ActiviteSelectionCategorieModal> {
  String? selectedCategorie;

  // Dégradé pastel standard YOLO
  final LinearGradient yoloSoftGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD7F3FF), // bleu pastel
      Color(0xFFFFE5F1), // rose pastel
      Color(0xFFFFF7D9), // jaune pastel
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        gradient: yoloSoftGradient,
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),

          // -------------------------------------------------------------------
          // 🔝 HEADER
          // -------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black87, size: 30),
                onPressed: () => Navigator.pop(context),
              ),

              const Text(
                "Choisir une catégorie",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------------------------
          // 📋 LISTE SIMPLE DES CATÉGORIES
          // -------------------------------------------------------------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: CategorieData.categories.entries.map((entry) {
                final name = entry.key;
                final emoji = entry.value["emoji"] as String;
                final examples = entry.value["examples"] as String;

                final isSelected = selectedCategorie == name;

                return GestureDetector(
                  onTap: () => setState(() => selectedCategorie = name),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.85)
                          : Colors.white.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Emoji
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const SizedBox(width: 14),

                        // Nom + exemples
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                examples,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Check
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(6),
                          child: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.black87, size: 22)
                              : const Icon(Icons.circle_outlined,
                                  color: Colors.black45, size: 22),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // -------------------------------------------------------------------
          // 🟩 BOUTON CONTINUER
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: GestureDetector(
              onTap: selectedCategorie == null
                  ? null
                  : () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActiviteCreationPage(
                            categorieInitiale: selectedCategorie!,
                          ),
                        ),
                      );
                    },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: selectedCategorie == null
                        ? [
                            Colors.black12,
                            Colors.black26,
                          ]
                        : const [
                            Color(0xFFA855F7),
                            Color(0xFFF97316),
                          ],
                  ),
                ),
                child: Center(
                  child: Text(
                    "Continuer",
                    style: TextStyle(
                      color: selectedCategorie == null
                          ? Colors.white70
                          : Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
