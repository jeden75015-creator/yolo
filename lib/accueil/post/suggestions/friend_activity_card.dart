import 'package:flutter/material.dart';
import '../../../activite/activite_fiche_page.dart';
import '../../../activite/activite_model.dart';

const LinearGradient yoloBackgroundGradient = LinearGradient(
  colors: [
    Color(0xFFFFFBEB),
    Color(0xFFFFF5EE),
    Color(0xFFEFF6FF),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

class FriendActivityNotificationCard extends StatelessWidget {
  final List<String> friendNames;
  final Activite activite;

  const FriendActivityNotificationCard({
    super.key,
    required this.friendNames,
    required this.activite,
  });

  @override
  Widget build(BuildContext context) {
    final message = friendNames.length == 1
        ? "Votre ami ${friendNames[0]} va participer à une activité 🎉"
        : "${friendNames.length} de vos amis vont participer à une activité 🎉";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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

          Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiviteFichePage(activiteId: activite.id),
                ),
              );
            },
            child: _activityPreview(),
          ),
        ],
      ),
    );
  }

  Widget _activityPreview() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: activite.photoUrl.isNotEmpty
                ? Image.network(activite.photoUrl, fit: BoxFit.cover)
                : Container(color: Colors.orange.shade200),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Text(
              activite.titre,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          )
        ],
      ),
    );
  }
}
