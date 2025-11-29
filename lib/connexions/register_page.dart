// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:firebase_auth/firebase_auth.dart';

// Project imports:
import 'auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String? selectedRegion;
  String? selectedOrientation;
  String? selectedGender;

  bool _isLoading = false;
  final Map<String, String?> errors = {};

  final List<String> regions = [
    'Auvergne-Rhône-Alpes',
    'Bourgogne-Franche-Comté',
    'Bretagne',
    'Centre-Val de Loire',
    'Corse',
    'Grand Est',
    'Hauts-de-France',
    'Île-de-France',
    'Normandie',
    'Nouvelle-Aquitaine',
    'Occitanie',
    'Pays de la Loire',
    'Provence-Alpes-Côte d’Azur',
    'Guadeloupe',
    'Martinique',
    'Guyane',
    'La Réunion',
    'Mayotte',
    'Saint-Martin',
    'Saint-Barthélemy',
    'Saint-Pierre-et-Miquelon',
    'Polynésie française',
    'Nouvelle-Calédonie',
    'Wallis-et-Futuna',
  ];

  final List<String> orientations = [
    'Hétérosexuel(le)',
    'Homosexuel(le)',
    'Bisexuel(le)',
    'Pansexuel(le)',
    'Asexuel(le)',
    'Autre / Préfère ne pas dire',
  ];
  final List<String> genders = [
  'Homme',
  'Femme',
  'Préférer ne pas dire',
  ];


  void _validateField(String field, String value) {
    setState(() {
      switch (field) {
        case 'Prénom':
          errors[field] = value.isEmpty ? 'Le prénom est obligatoire.' : null;
          break;
        case 'Ville':
          errors[field] = value.isEmpty ? 'La ville est obligatoire.' : null;
          break;
        case 'Email':
          if (value.isEmpty) {
            errors[field] = 'L’email est obligatoire.';
          } else if (!value.contains('@') || !value.contains('.')) {
            errors[field] = 'Email invalide.';
          } else {
            errors[field] = null;
          }
          break;
        case 'Mot de passe':
          if (value.isEmpty) {
            errors[field] = 'Mot de passe obligatoire.';
          } else if (value.length < 6) {
            errors[field] = '6 caractères minimum.';
          } else {
            errors[field] = null;
          }
          break;
        case 'Date':
          errors[field] = value.isEmpty
              ? 'Date de naissance obligatoire.'
              : null;
          break;
      }
    });
  }

  Future<void> _validateAndContinue() async {
    final firstName = firstNameController.text.trim();
    final city = cityController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final birthDate = birthDateController.text.trim();
    final bio = bioController.text.trim();

    if (firstName.isEmpty ||
        city.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        birthDate.isEmpty ||
        selectedRegion == null ||
        selectedOrientation == null) {
      setState(() {
        _validateField('Prénom', firstName);
        _validateField('Ville', city);
        _validateField('Email', email);
        _validateField('Mot de passe', password);
        _validateField('Date', birthDate);
      });
      return;
    }
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sélectionne ton genre.")),
       );
       return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(email, password);
      if (user != null) {
        await _authService.saveUserProfile(
          uid: user.uid,
          firstName: firstName,
          email: email,
          region: selectedRegion!,
          gender: selectedGender!,
          orientation: selectedOrientation!,
          birthDate: birthDate,
          bio: bio,
          city: city,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Compte créé avec succès 🎉"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PhotoPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = "Cette adresse e-mail est déjà utilisée.";
          break;
        case 'weak-password':
          message = "Le mot de passe doit contenir au moins 6 caractères.";
          break;
        case 'invalid-email':
          message = "Adresse e-mail invalide.";
          break;
        default:
          message = "Erreur d'inscription : ${e.message}";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur inattendue : $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // 🌅 Fond orange → rouge corail
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Bouton retour (bulle bleue)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1565C0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Center(
                  child: Text(
                    "Créer ton profil YOLO",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                _buildFormCard(),
                const SizedBox(height: 35),

                // 🔸 Bouton principal
                GestureDetector(
                  onTap: _isLoading ? null : _validateAndContinue,
                  child: Container(
                    width: 300,
                    height: 52,
                    margin: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFA855F7), Color(0xFFF97316)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Créer mon compte",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Déjà un compte ? Se connecter",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧩 Carte du formulaire (inchangée)
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Color(0xFFFFF1F2), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildValidatedField("Prénom", controller: firstNameController),
          _buildValidatedField("Ville", controller: cityController),
          _buildValidatedField("Email", controller: emailController),
          _buildValidatedField(
            "Mot de passe",
            controller: passwordController,
            obscure: true,
          ),
          _buildValidatedField("Date", controller: birthDateController),
          const SizedBox(height: 10),
          _buildDropdown(
            "Genre",
            genders,
           (v) => setState(() => selectedGender = v),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  "Région",
                  regions,
                  (v) => setState(() => selectedRegion = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  "Orientation",
                  orientations,
                  (v) => setState(() => selectedOrientation = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildBio(),
        ],
      ),
    );
  }

  Widget _buildValidatedField(
    String label, {
    bool obscure = false,
    TextEditingController? controller,
  }) {
    final isValid = errors[label] == null && controller!.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: (v) => _validateField(label, v),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: isValid
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        ),
        if (errors[label] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              errors[label]!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBio() {
    return TextField(
      controller: bioController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Bio',
        hintText: 'Parle un peu de toi...',
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ✅ Fallback simple
class PhotoPage extends StatelessWidget {
  const PhotoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo de profil')),
      body: const Center(
        child: Text('Ici, vous pouvez ajouter ou prendre une photo de profil.'),
      ),
    );
  }
}
