import 'package:flutter/material.dart';

const LinearGradient yoloBackgroundGradient = LinearGradient(
  colors: [
    Color(0xFFFFFBEB), // beige clair
    Color(0xFFFFF5EE), // pêche très pâle
    Color(0xFFEFF6FF), // bleu lavande clair
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class NewUserLite {
  final String id;
  final String name;
  final String? photoUrl;

  const NewUserLite({
    required this.id,
    required this.name,
    this.photoUrl,
  });
}

class NewUsersCard extends StatelessWidget {
  final List<NewUserLite> newUsers;

  const NewUsersCard({super.key, required this.newUsers});

  @override
  Widget build(BuildContext context) {
    final count = newUsers.length;

    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: yoloBackgroundGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withOpacity(0.07),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Nouvelles personnes sur YOLO 🎉",
            style: TextStyle(
              fontSize: 15, // <= 16
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          if (count == 1) _singleUser(context, newUsers.first),

          if (count > 1) _grid(context),

          if (count > 6)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/new_users");
                },
                child: const Text(
                  "Voir plus",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _singleUser(BuildContext context, NewUserLite u) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, "/profile", arguments: u.id),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage:
                (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                    ? NetworkImage(u.photoUrl!)
                    : null,
            child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            u.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final take = newUsers.take(6).toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: take.map((u) {
        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, "/profile", arguments: u.id),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                        ? NetworkImage(u.photoUrl!)
                        : null,
                child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 22)
                    : null,
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: Text(
                  u.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
