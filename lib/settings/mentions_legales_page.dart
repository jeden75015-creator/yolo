// Flutter imports:
import 'package:flutter/material.dart';

class MentionsLegalesPage extends StatelessWidget {
  const MentionsLegalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        title: const Text(
          'Mentions légales',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '''
  Mentions légales – Application YOLO

---

   1. Éditeur de l’application

L’application YOLO est éditée par :  
Seaman D.
Email de contact : yolo@yologo.app

Directeur de la publication : Seaman .D

---

   2. Hébergeur

L’application YOLO est hébergée par :  
  Google Cloud (Firebase)
1600 Amphitheatre Parkway  
Mountain View, CA 94043 – États-Unis  
Site web : [https://firebase.google.com](https://firebase.google.com)

Les données sont hébergées sur les serveurs européens de Google Cloud, conformément au Règlement Général sur la Protection des Données (RGPD).

---

   3. Propriété intellectuelle

Tous les éléments de l’application YOLO (textes, images, graphismes, logos, icônes, sons, logiciels, etc.) sont la propriété exclusive de Seaman.D, sauf mention contraire.  
Toute reproduction, représentation, modification, publication ou adaptation, totale ou partielle, est interdite sans autorisation écrite préalable.

---

   4. Données personnelles et confidentialité

L’application YOLO collecte et traite des données personnelles strictement nécessaires à son fonctionnement.  
Les données concernées peuvent inclure :

- Adresse e-mail, pseudonyme, photo de profil ;  
- Informations techniques (appareil, langue, logs de connexion) ;  
- Données d’utilisation (messages, interactions, préférences).

Ces données sont utilisées uniquement dans le cadre du bon fonctionnement de l’application et ne sont ni revendues, ni partagées à des tiers non autorisés.

Conformément au RGPD (Règlement UE 2016/679) et à la loi Informatique et Libertés, tu peux exercer tes droits d’accès, de rectification, de suppression ou d’opposition à tout moment en écrivant à :  
  yolo@yologo.app

---

  5. Cookies et traceurs

YOLO peut utiliser des cookies ou technologies similaires pour améliorer ton expérience utilisateur et mesurer la fréquentation.  
Tu peux à tout moment désactiver ces traceurs depuis les paramètres de ton appareil.

---

   6. Responsabilité

YOLO s’efforce d’assurer la disponibilité et la fiabilité de ses services, mais ne peut être tenue responsable :  

- d’erreurs ou d’omissions dans le contenu,  
- d’interruptions temporaires,  
- ou de l’usage que les utilisateurs font de la plateforme.

Chaque utilisateur est responsable de ses publications et de ses échanges via l’application.

---

   7. Droit applicable

Les présentes mentions légales sont régies par le droit français.  
En cas de litige, les tribunaux compétents seront ceux du ressort du domicile de l’éditeur.
          ''',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
        ),
      ),
    );
  }
}
