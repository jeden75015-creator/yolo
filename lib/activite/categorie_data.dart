import 'package:flutter/material.dart';
import 'package:yolo/widgets/helpers/storage_helper.dart';

class CategorieData {
  static final Map<String, Map<String, dynamic>> categories = {
    "Sortir": {
      "emoji": "🍹",
      "color": const Color.fromARGB(255, 73, 227, 244),
      "textColor": const Color.fromARGB(255, 14, 2, 46),
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/sortir.png",
      ),
      "examples": "Soirées, bars, concerts, festivals",
    },

    "Bouger": {
      "emoji": "🏃",
      "color": const Color.fromARGB(255, 255, 15, 155),
      "textColor": Colors.black,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/bouger.jpg",
      ),
      "examples": "Sport, rando, yoga, fitness",
    },

    "Applaudir": {
      "emoji": "🎭",
      "color": const Color.fromARGB(255, 0, 255, 102),
      "textColor": Colors.black,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/applaudir.jpg",
      ),
      "examples": "Cinéma, théâtre, spectacles, concerts",
    },

    "Découvrir": {
      "emoji": "🌅",
      "color": const Color.fromARGB(255, 253, 148, 2),
      "textColor": Colors.black,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/decouvrir.png",
      ),
      "examples": "Nature, expositions, voyages",
    },

    "Apprendre": {
      "emoji": "📚",
      "color": const Color.fromARGB(255, 187, 246, 223),
      "textColor": Colors.black,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/apprendre.jpg",
      ),
      "examples": "Cours, conférences, échanges",
    },

    "Manger": {
      "emoji": "🍽️",
      "color": const Color.fromARGB(255, 213, 239, 16),
      "textColor": Colors.black,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/manger.jpg",
      ),
      "examples": "Brunchs, food trucks, pique-niques",
    },

    "Boire": {
      "emoji": "🍷",
      "color": const Color.fromARGB(255, 92, 11, 168),
      "textColor": Colors.white,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/boire.jpg",
      ),
      "examples": "Bars, cocktails, dégustations",
    },

    "Danser": {
      "emoji": "💃",
      "color": const Color.fromARGB(255, 183, 5, 94),
      "textColor": const Color.fromARGB(255, 248, 248, 248),
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/danser.jpg",
      ),
      "examples": "Club, salsa, danse libre",
    },

    "Jouer": {
      "emoji": "🎲",
      "color": const Color(0xFFE8B80D),
      "textColor": Colors.black,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/jouer.jpg",
      ),
      "examples": "Jeux de société, quiz, escape game",
    },

    "Discuter": {
      "emoji": "☕",
      "color": const Color.fromARGB(255, 7, 49, 109),
      "textColor": Colors.white,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/discuter.jpg",
      ),
      "examples": "Cafés philo, débats, rencontres",
    },

    "S'engager": {
      "emoji": "🌍",
      "color": const Color.fromARGB(255, 4, 78, 39),
      "textColor": Colors.white,
      "image": StorageHelper.convert(
        "gs://yolo-d90ce.firebasestorage.app/categories/sengager.jpg",
      ),
      "examples": "Écologie, bénévolat, solidarité, causes sociales",
    },
  };
}
