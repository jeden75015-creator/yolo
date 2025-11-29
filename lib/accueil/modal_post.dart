import 'package:flutter/material.dart';

Future<String?> showModalPostSelector(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFA726),
                  Color(0xFFFFCC80),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Que veux-tu créer ?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 25),

                _ChoiceButton(
                  icon: Icons.edit,
                  title: "Post classique",
                  subtitle: "Texte, image, carrousel...",
                  onTap: () => Navigator.pop(context, "post"),
                ),

                const SizedBox(height: 15),

                _ChoiceButton(
                  icon: Icons.poll_rounded,
                  title: "Créer un sondage",
                  subtitle: "Pose une question + 1 à 4 options.",
                  onTap: () => Navigator.pop(context, "poll"),
                ),

                const SizedBox(height: 15),

                _ChoiceButton(
                  icon: Icons.event_available,
                  title: "Créer une activité",
                  subtitle: "Date, lieu, photo, participants...",
                  onTap: () => Navigator.pop(context, "activite"),
                ),

                const SizedBox(height: 15),

                _ChoiceButton(
                  icon: Icons.groups_rounded,
                  title: "Créer un groupe",
                  subtitle: "Discussion, photo, membres...",
                  onTap: () => Navigator.pop(context, "groupe"),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.deepOrangeAccent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
