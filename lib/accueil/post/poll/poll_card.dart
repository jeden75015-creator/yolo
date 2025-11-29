import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../post_model.dart';
import '../post_service.dart';
import '../../../profil/profil.dart';

class PollCard extends StatelessWidget {
  final Post post;

  const PollCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final p = post;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    final totalVotes = p.options.fold<int>(0, (sum, o) => sum + o.votes);
    final hasVoted = p.voted.contains(uid);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      padding: const EdgeInsets.only(bottom: 16, top: 16),

      // 🔥 Dégradé YOLO en arrière-plan
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFBEB), // beige clair
            Color(0xFFFFF5EE), // pêche très pâle
            Color(0xFFEFF6FF), // bleu lavande clair
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ------------------------------------------------------
          // QUESTION (titre) avec dégradé
          // ------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFFF97316), // orange
                    Color(0xFFA855F7), // violet
                  ],
                ).createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                );
              },
              child: Text(
                p.question ?? "",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white, // indispensable avec ShaderMask
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // OPTIONS AVEC BARRES ORANGES
          // ------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(p.options.length, (i) {
                final option = p.options[i];
                final percent =
                    totalVotes == 0 ? 0.0 : option.votes / totalVotes;

                return GestureDetector(
                  onTap: hasVoted
                      ? null
                      : () async {
                          await PostService().votePoll(
                            postId: p.id,
                            optionIndex: i,
                          );
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: hasVoted
                          ? const Color.fromARGB(122, 162, 243, 233) // léger orange
                          : Colors.white.withOpacity(0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Option + nombre de votes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option.text,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            Text(
                              "${option.votes} votes",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Barre orange
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // BAS DE CARTE : créateur à GAUCHE / likes + commentaires
          // ------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [

                // Créateur
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: p.userId),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: p.userPhoto != null &&
                                p.userPhoto!.isNotEmpty
                            ? NetworkImage(p.userPhoto!)
                            : null,
                        child: (p.userPhoto == null || p.userPhoto!.isEmpty)
                            ? const Icon(Icons.person, color: Color.fromARGB(255, 49, 40, 40))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 32, 26, 26),
                            ),
                          ),
                          Text(
                            DateFormat("dd MMM • HH:mm", "fr_FR").format(p.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(179, 35, 28, 28),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ❤️ Total likes
                GestureDetector(
                  onTap: () async {
                    if (uid == null) return;
                    await PostService().toggleLike(p.id);
                  },
                  child: Icon(
                    p.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: p.likedByMe ? Colors.red : const Color.fromARGB(255, 68, 67, 67),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "${p.likes}", // nombre total des likes
                  style:
                      const TextStyle(color: Color.fromARGB(255, 122, 116, 116), fontSize: 14, fontWeight: FontWeight.w600),
                ),

                const SizedBox(width: 18),

                // 💬 Commentaires
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, "/comments", arguments: p.id);
                  },
                  child: const Icon(Icons.comment, color: Color.fromARGB(179, 65, 63, 63)),
                ),
                const SizedBox(width: 6),
                Text(
                  "${p.commentsCount}",
                  style: const TextStyle(color: Color.fromARGB(255, 55, 52, 52)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
