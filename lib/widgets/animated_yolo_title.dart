import 'package:flutter/material.dart';

class AnimatedYoloTitle extends StatefulWidget {
  const AnimatedYoloTitle({super.key});

  @override
  State<AnimatedYoloTitle> createState() => _AnimatedYoloTitleState();
}

class _AnimatedYoloTitleState extends State<AnimatedYoloTitle>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        // YOLO en blanc, mais chacun garde son petit mouvement distinct
        _WhiteLetter(letter: "Y", offset: -10),
        _WhiteLetter(letter: "O", offset: 14),
        _WhiteLetter(letter: "L", offset: -12),
        _WhiteLetter(letter: "O", offset: 18),
      ],
    );
  }
}

class _WhiteLetter extends StatelessWidget {
  final String letter;
  final double offset;

  const _WhiteLetter({required this.letter, required this.offset});

  @override
  Widget build(BuildContext context) {
    // Ce widget n’est qu’un proxy pour simplifier le Row dans le build
    return AnimatedBuilder(
      animation: (context
              .findAncestorStateOfType<_AnimatedYoloTitleState>()!)
          ._controller,
      builder: (_, child) {
        final controller =
            context.findAncestorStateOfType<_AnimatedYoloTitleState>()!._controller;
        final bounce = (1 - controller.value) * offset;

        return Transform.translate(
          offset: Offset(0, bounce),
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
