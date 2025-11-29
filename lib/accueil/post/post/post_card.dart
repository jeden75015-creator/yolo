import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../post_model.dart';
import '../post_service.dart';
import '../../../profil/profil.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Post>(
      stream: PostService().streamSinglePost(post.id),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final p = snap.data!;
        final uid = FirebaseAuth.instance.currentUser?.uid;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFFBEB),
                Color(0xFFFFF5EE),
                Color(0xFFEFF6FF),
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
            children: [

              // ---------------------------------------------------------
              // TITRE CENTRÉ
              // ---------------------------------------------------------
              if (p.titre != null && p.titre!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  child: Text(
                    p.titre!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // TEXTE
              if (p.texte != null && p.texte!.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    p.texte!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),

              // ---------------------------------------------------------
              // CAROUSEL PHOTO
              // ---------------------------------------------------------
              if (p.photoUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 260,
                    child: PageView.builder(
                      itemCount: p.photoUrls.length,
                      itemBuilder: (_, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              p.photoUrls[i],
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ---------------------------------------------------------
              // BAS DE POST : avatar + nom + date ←→ likes & comments
              // ---------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [

                    // -------------------------
                    // AVATAR + NOM + DATE
                    // -------------------------
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
                            backgroundImage: (p.userPhoto != null &&
                                    p.userPhoto!.isNotEmpty)
                                ? NetworkImage(p.userPhoto!)
                                : null,
                            child: (p.userPhoto == null ||
                                    p.userPhoto!.isEmpty)
                                ? const Icon(Icons.person,
                                    color: Colors.white)
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
                                ),
                              ),
                              Text(
                                DateFormat("dd MMM • HH:mm", "fr_FR")
                                    .format(p.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // -------------------------
                    // LIKE
                    // -------------------------
                    GestureDetector(
                      onTap: () async {
                        if (uid == null) return;
                        await PostService().toggleLike(p.id);
                      },
                      child: Icon(
                        p.likedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: p.likedByMe ? Colors.red : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${p.likes}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 18),

                    // -------------------------
                    // COMMENTAIRES
                    // -------------------------
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "/comments",
                          arguments: p.id,
                        );
                      },
                      child: const Icon(
                        Icons.comment,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${p.commentsCount}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
