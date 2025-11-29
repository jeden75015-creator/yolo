import 'package:flutter/material.dart';

class PostCarousel extends StatefulWidget {
  final List<String> photoUrls;

  /// Hauteur standard (même taille que les activités)
  final double height;

  const PostCarousel({
    super.key,
    required this.photoUrls,
    this.height = 260,
  });

  @override
  State<PostCarousel> createState() => _PostCarouselState();
}

class _PostCarouselState extends State<PostCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photoUrls;

    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // ------------------------------------------------------------
          // 🔥 CARROUSEL IMAGES
          // ------------------------------------------------------------
          PageView.builder(
            controller: _controller,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  photos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: widget.height,
                ),
              );
            },
          ),

          // ------------------------------------------------------------
          // 🔥 FLÈCHE GAUCHE
          // ------------------------------------------------------------
          Positioned(
            left: 8,
            top: widget.height / 2 - 20,
            child: _arrowButton(
              icon: Icons.chevron_left,
              onTap: () {
                if (_index > 0) {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),

          // ------------------------------------------------------------
          // 🔥 FLÈCHE DROITE
          // ------------------------------------------------------------
          Positioned(
            right: 8,
            top: widget.height / 2 - 20,
            child: _arrowButton(
              icon: Icons.chevron_right,
              onTap: () {
                if (_index < photos.length - 1) {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              },
            ),
          ),

          // ------------------------------------------------------------
          // 🔥 INDICATEURS (•••)
          // ------------------------------------------------------------
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _index == i ? 10 : 6,
                  height: _index == i ? 10 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _index == i ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔧 Widget flèche
  // ------------------------------------------------------------
  Widget _arrowButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
