import 'package:flutter/material.dart';

class ImagePickerMenu extends StatelessWidget {
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;

  const ImagePickerMenu({
    super.key,
    required this.onPickCamera,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Prendre une photo"),
            onTap: onPickCamera,
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choisir depuis la galerie"),
            onTap: onPickGallery,
          ),
        ],
      ),
    );
  }
}
