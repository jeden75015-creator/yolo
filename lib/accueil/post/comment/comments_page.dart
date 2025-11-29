import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'comment_model.dart';
import 'comment_service.dart';
import '../../../theme/app_colors.dart';
import 'package:yolo/profil/profil.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final TextEditingController _controller = TextEditingController();
  final CommentService _commentService = CommentService();

  late String postId;
  String? replyingTo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    postId = ModalRoute.of(context)!.settings.arguments as String;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(replyingTo == null ? "Commentaires" : "Répondre..."),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: _commentService.getComments(postId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snap.data!;
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        "Aucun commentaire pour l’instant.",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final parents =
                      comments.where((c) => c.parentId == null).toList();

                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: parents.map((c) {
                      final replies = comments
                          .where((r) => r.parentId == c.id)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _commentTile(c),
                          ...replies.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(left: 45),
                              child: _commentTile(r),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            _inputField(),
          ],
        ),
      ),
    );
  }

  Widget _commentTile(CommentModel c) {
    final dateStr = DateFormat("dd MMM HH:mm", "fr_FR").format(c.date);
    final isMine = c.userId == FirebaseAuth.instance.currentUser!.uid;

    return Dismissible(
      key: Key(c.id),
      direction: isMine ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) {
        _commentService.deleteComment(postId, c.id);
      },
      background: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(userId: c.userId),
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: c.userPhoto.isNotEmpty
                        ? NetworkImage(c.userPhoto)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: c.userPhoto.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(userId: c.userId),
                          ),
                        ),
                        child: Text(
                          c.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.texte,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => setState(() => replyingTo = c.id),
                            child: const Text(
                              "Répondre",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _reactionBar(c),
          ],
        ),
      ),
    );
  }

  Widget _reactionBar(CommentModel c) {
    return StreamBuilder<CommentReactions>(
      stream: _commentService.getReactions(postId, c.id),
      builder: (context, snap) {
        final data = snap.data;
        final counts =
            data?.counts ?? {"like": 0, "love": 0, "haha": 0, "wow": 0};
        final myType = data?.myType;

        Widget reactionBtn(String type, String emoji) {
          final isActive = myType == type;
          final count = counts[type] ?? 0;

          return GestureDetector(
            onTap: () {
              _commentService.setReaction(
                postId: postId,
                commentId: c.id,
                type: type,
                currentType: myType,
              );
            },
            child: Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: isActive ? 20 : 18)),
                if (count > 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    "$count",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
                const SizedBox(width: 10),
              ],
            ),
          );
        }

        return Row(
          children: [
            reactionBtn("like", "👍"),
            reactionBtn("love", "❤️"),
            reactionBtn("haha", "😂"),
            reactionBtn("wow", "😮"),
          ],
        );
      },
    );
  }

  Widget _inputField() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          if (replyingTo != null)
            GestureDetector(
              onTap: () => setState(() => replyingTo = null),
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.reply, color: Colors.orange),
              ),
            ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText:
                    replyingTo == null ? "Écris un commentaire..." : "Répondre...",
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _sendComment,
            child: const Icon(Icons.send, color: Colors.orange, size: 28),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await _commentService.addComment(
      postId: postId,
      texte: text,
      parentId: replyingTo,
    );

    _controller.clear();
    setState(() => replyingTo = null);
  }
}
