// Dart imports:
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart' show kIsWeb;

// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io' as io; // 📱 Android/iOS
import 'dart:html' as html; // 🌐 Web

/// 🔹 AuthService : gestion utilisateur + upload image
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------------------------------------
  // 🔐 CONNEXION
  // ---------------------------------------------
  Future<User?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur de connexion : ${e.message}');
      rethrow;
    }
  }

  // ---------------------------------------------
  // 🧩 INSCRIPTION
  // ---------------------------------------------
  Future<User?> register(String email, String password) async {
    try {
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Le mot de passe doit contenir au moins 6 caractères.',
        );
      }
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase Auth : ${e.code} - ${e.message}');
      rethrow;
    }
  }

  // ---------------------------------------------
  // ☁️ UPLOAD IMAGE (Web + Mobile)
  // ---------------------------------------------
  Future<String?> uploadProfileImage(
    String uid,
    dynamic imageFile, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('user_profiles/$uid.jpg');
      UploadTask uploadTask;

      if (kIsWeb) {
        if (imageFile is Uint8List) {
          final blob = html.Blob([imageFile]);
          uploadTask = ref.putBlob(blob);
        } else {
          throw Exception("Format d'image non supporté sur le Web.");
        }
      } else {
        final io.File file = imageFile as io.File;
        uploadTask = ref.putFile(file);
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        onProgress?.call(progress);
        print("📤 Upload : ${progress.toStringAsFixed(2)}%");
      });

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      print("✅ Image uploadée : $url");
      return url;
    } catch (e) {
      print('❌ Erreur upload image : $e');
      return null;
    }
  }

  // --------------------------------------------------------------
  // 🧾 ENREGISTREMENT DU PROFIL DANS FIRESTORE
  // --------------------------------------------------------------
  Future<void> saveUserProfile({
    required String uid,
    required String firstName,
    required String email,
    required String region,
    required String orientation,
    required String birthDate,
    required String bio,
    required String gender, // 🔥 AJOUT ICI
    String? city,
    dynamic imageFile,
  }) async {
    String? photoUrl;

    if (imageFile != null) {
      photoUrl = await uploadProfileImage(uid, imageFile);
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': firstName,
        'email': email,
        'region': region,
        'orientation': orientation,
        'birthDate': birthDate,
        'bio': bio,
        'city': city ?? '',
        'gender': gender, // 🔥🔥🔥 ENREGISTREMENT DU GENRE
        'photoUrl': photoUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Profil enregistré dans Firestore.');
    } catch (e) {
      print('❌ Erreur Firestore : $e');
      rethrow;
    }
  }

  // ---------------------------------------------
  // 🖼️ MISE À JOUR PHOTO
  // ---------------------------------------------
  Future<void> updatePhotoUrl(String uid, String url) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Photo mise à jour.');
    } catch (e) {
      print('❌ Erreur update photo : $e');
      rethrow;
    }
  }

  // ---------------------------------------------
  // 🚪 DÉCONNEXION
  // ---------------------------------------------
  Future<void> logout() async {
    try {
      await _auth.signOut();
      print('👋 Déconnecté avec succès');
    } catch (e) {
      print('❌ Erreur déconnexion : $e');
    }
  }
}
