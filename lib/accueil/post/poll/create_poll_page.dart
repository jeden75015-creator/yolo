import 'package:flutter/material.dart';
import 'package:yolo/theme/app_colors.dart';
import 'poll_preview_page.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  // --------------------------------------------
  // Ajouter une option
  // --------------------------------------------
  void addOption() {
    if (optionControllers.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum de 6 options.")),
      );
      return;
    }

    setState(() {
      optionControllers.add(TextEditingController());
    });
  }

  // --------------------------------------------
  // Supprimer une option
  // --------------------------------------------
  void removeOption(int index) {
    if (optionControllers.length > 2) {
      setState(() => optionControllers.removeAt(index));
    }
  }

  // --------------------------------------------
  // Ouvrir le preview YOLO
  // --------------------------------------------
  Future<void> openPreview() async {
    final question = questionController.text.trim();
    final options = optionControllers
        .map((c) => c.text.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Vous devez saisir une question + au moins 2 options."),
        ),
      );
      return;
    }

    final published = await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => PollPreviewPage(
          question: question,
          options: options,
        ),
      ),
    );

    if (published == true) {
      Navigator.pop(context, true);
    }
  }

  // --------------------------------------------
  // UI
  // --------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          title: const Text(
            "Créer un sondage",
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // --------------------------------------
              // QUESTION
              // --------------------------------------
              TextField(
                controller: questionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Question du sondage",
                  labelStyle: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 30),

              // --------------------------------------
              // OPTIONS
              // --------------------------------------
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: optionControllers.length,
                itemBuilder: (_, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: optionControllers[index],
                            decoration: InputDecoration(
                              labelText: "Option ${index + 1}",
                              labelStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Bouton supprimer
                        if (optionControllers.length > 2)
                          IconButton(
                            splashRadius: 20,
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: () => removeOption(index),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // --------------------------------------
              // Ajouter une option
              // --------------------------------------
              TextButton(
                onPressed: addOption,
                child: const Text(
                  "Ajouter une option",
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 40),

              // --------------------------------------
              // BOUTON APERÇU YOLO
              // --------------------------------------
              GestureDetector(
                onTap: openPreview,
                child: Container(
                  height: 54,
                  width: 260,
                  decoration: BoxDecoration(
                    gradient: AppColors.mainGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Text(
                      "Aperçu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
