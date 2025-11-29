import 'package:flutter/material.dart';

class YOLOSegmentControl extends StatelessWidget {
  final int currentIndex;
  final Function(int) onChanged;
  final List<String> tabs;

  const YOLOSegmentControl({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Taille responsive
    double height = width < 330 ? 34 : 38;
    double fontSize = width < 330 ? 12 : 14;
    double radius = 14;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final bool active = index == currentIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  color: active
                      ? const Color(0xFFF97316).withOpacity(0.85)
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
