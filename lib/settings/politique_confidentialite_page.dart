// Flutter imports:
import 'package:flutter/material.dart';

class PolitiqueConfidentialitePage extends StatelessWidget {
  const PolitiqueConfidentialitePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9800),
        title: const Text(
          'Politique de confidentialité',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '''
      Politique de confidentialité – Application YOLO

---

   1. Introduction

Cette politique de confidentialité a pour objectif d’informer les utilisateurs de l’application YOLO sur la manière dont leurs données personnelles sont collectées, utilisées et protégées.

YOLO s’engage à respecter la vie privée de ses utilisateurs et à assurer la conformité de ses traitements avec le Règlement Général sur la Protection des Données (RGPD) et la loi Informatique et Libertés.

---

  2. Responsable du traitement

Le responsable du traitement des données est :  
Seaman D. 
 Contact : yolo@yologo.app

---

   3. Données collectées

YOLO collecte uniquement les informations nécessaires au bon fonctionnement de l’application :  

- Identifiants (adresse e-mail, pseudonyme, photo de profil) ;  
- Données d’utilisation (messages, interactions, préférences) ;  
- Informations techniques (modèle de téléphone, langue, logs de connexion).

Aucune donnée sensible n’est collectée.

---

  4. Finalités de la collecte

Les données collectées sont utilisées pour :  

- Permettre le fonctionnement de l’application et de ses fonctionnalités sociales ;  
- Améliorer l’expérience utilisateur et les performances de l’app ;  
- Garantir la sécurité du service ;  
- Envoyer, le cas échéant, des notifications pertinentes.

Aucune donnée n’est vendue ni partagée avec des tiers non autorisés.

---

   5. Conservation des données

Les données sont conservées uniquement pendant la durée nécessaire aux finalités décrites ci-dessus.  
En cas de suppression de compte, toutes les données associées sont supprimées dans un délai maximum de **30 jours**.

---

  6. Sécurité des données

YOLO utilise les services Google Cloud (Firebase), hébergés dans l’Union européenne, pour stocker les données de manière sécurisée.  
Des mesures techniques (chiffrement, authentification sécurisée, pare-feu) protègent les informations contre toute perte, utilisation abusive ou accès non autorisé.

---

  7. Droits des utilisateurs

Conformément au RGPD, chaque utilisateur dispose des droits suivants :  

- Droit d’accès, de rectification, de suppression et d’opposition ;  
- Droit à la limitation du traitement ;  
- Droit à la portabilité des données.

Ces droits peuvent être exercés à tout moment en écrivant à :  yolo@yologo.app

---

   8. Cookies et traceurs

YOLO peut utiliser des cookies ou traceurs pour analyser la fréquentation et améliorer l’expérience utilisateur.  
Tu peux désactiver ces traceurs dans les paramètres de ton appareil.

---

   9. Partage et transfert de données

Aucun transfert de données hors de l’Union européenne n’est effectué.  
Les seules données partagées le sont avec des prestataires techniques nécessaires au fonctionnement de l’app (hébergement, authentification, analytics).

---

   10. Modifications de la politique

YOLO peut modifier la présente politique pour s’adapter à l’évolution légale ou technique du service.  
Les utilisateurs seront informés de toute mise à jour via l’application.

---

  11. Contact

Pour toute question relative à cette politique de confidentialité ou à tes données personnelles, écris-nous à :  
yolo@yologo.app

---

Dernière mise à jour : novembre 2025
          ''',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
        ),
      ),
    );
  }
}
